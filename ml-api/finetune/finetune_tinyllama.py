"""
Fine-tune TinyLlama (1.1B) for CineFlow Movie Chatbot using LoRA.

This script fine-tunes TinyLlama with your movie training data using
QLoRA (Quantized LoRA) for efficient training on consumer GPUs.

Requirements:
- GPU with 8GB+ VRAM (or use Google Colab free tier)
- Install requirements: pip install -r requirements.txt

After training, upload to Hugging Face:
- Your model will work with the CineFlow cloud API
"""

import os
import torch
from datasets import load_dataset
from transformers import (
    AutoModelForCausalLM,
    AutoTokenizer,
    BitsAndBytesConfig,
    TrainingArguments,
)
from peft import LoraConfig, get_peft_model, prepare_model_for_kbit_training
from trl import SFTTrainer
from huggingface_hub import login


# Configuration
BASE_MODEL = "TinyLlama/TinyLlama-1.1B-Chat-v1.0"  # Small, fast, good for movies
OUTPUT_DIR = "./cinebot-tinyllama"
HF_USERNAME = os.getenv("HF_USERNAME", "your-username")  # Change this!
MODEL_NAME = "cinebot-movie-expert"


def setup_model():
    """Load base model with 4-bit quantization for efficient training."""
    print(f"📦 Loading {BASE_MODEL}...")
    
    # 4-bit quantization config for efficient training
    bnb_config = BitsAndBytesConfig(
        load_in_4bit=True,
        bnb_4bit_quant_type="nf4",
        bnb_4bit_compute_dtype=torch.float16,
        bnb_4bit_use_double_quant=True,
    )
    
    # Load model
    model = AutoModelForCausalLM.from_pretrained(
        BASE_MODEL,
        quantization_config=bnb_config,
        device_map="auto",
        trust_remote_code=True,
    )
    
    # Load tokenizer
    tokenizer = AutoTokenizer.from_pretrained(BASE_MODEL)
    tokenizer.pad_token = tokenizer.eos_token
    tokenizer.padding_side = "right"
    
    return model, tokenizer


def setup_lora(model):
    """Configure LoRA adapters for efficient fine-tuning."""
    print("🔧 Setting up LoRA...")
    
    # Prepare model for training
    model = prepare_model_for_kbit_training(model)
    
    # LoRA configuration
    lora_config = LoraConfig(
        r=16,  # LoRA rank
        lora_alpha=32,
        target_modules=[
            "q_proj", "k_proj", "v_proj", "o_proj",  # Attention
            "gate_proj", "up_proj", "down_proj",  # MLP
        ],
        lora_dropout=0.05,
        bias="none",
        task_type="CAUSAL_LM",
    )
    
    model = get_peft_model(model, lora_config)
    model.print_trainable_parameters()
    
    return model


def load_data(tokenizer):
    """Load and format training data."""
    print("📚 Loading training data...")
    
    # Load the JSONL file
    dataset = load_dataset("json", data_files="movie_training_chat.jsonl", split="train")
    
    def format_chat(example):
        """Format as TinyLlama chat template."""
        messages = example["messages"]
        formatted = ""
        for msg in messages:
            role = msg["role"]
            content = msg["content"]
            if role == "system":
                formatted += f"<|system|>\n{content}</s>\n"
            elif role == "user":
                formatted += f"<|user|>\n{content}</s>\n"
            elif role == "assistant":
                formatted += f"<|assistant|>\n{content}</s>\n"
        return {"text": formatted}
    
    dataset = dataset.map(format_chat)
    return dataset


def train(model, tokenizer, dataset):
    """Run fine-tuning."""
    print("🚀 Starting training...")
    
    training_args = TrainingArguments(
        output_dir=OUTPUT_DIR,
        num_train_epochs=3,
        per_device_train_batch_size=4,
        gradient_accumulation_steps=4,
        learning_rate=2e-4,
        weight_decay=0.01,
        warmup_ratio=0.03,
        logging_steps=10,
        save_steps=100,
        save_total_limit=2,
        fp16=True,
        optim="paged_adamw_8bit",
        lr_scheduler_type="cosine",
        report_to="none",  # Set to "wandb" if using Weights & Biases
    )
    
    trainer = SFTTrainer(
        model=model,
        train_dataset=dataset,
        tokenizer=tokenizer,
        args=training_args,
        dataset_text_field="text",
        max_seq_length=512,
        packing=True,
    )
    
    trainer.train()
    
    # Save the model
    print(f"💾 Saving model to {OUTPUT_DIR}...")
    trainer.save_model(OUTPUT_DIR)
    tokenizer.save_pretrained(OUTPUT_DIR)
    
    return trainer


def push_to_hub(model, tokenizer):
    """Upload model to Hugging Face Hub."""
    print("☁️ Pushing to Hugging Face Hub...")
    
    # Login to Hugging Face
    hf_token = os.getenv("HF_API_TOKEN")
    if hf_token:
        login(token=hf_token)
    else:
        print("⚠️  Set HF_API_TOKEN environment variable or run `huggingface-cli login`")
        return
    
    repo_id = f"{HF_USERNAME}/{MODEL_NAME}"
    
    # Push model and tokenizer
    model.push_to_hub(repo_id, use_temp_dir=True)
    tokenizer.push_to_hub(repo_id)
    
    print(f"✅ Model uploaded to: https://huggingface.co/{repo_id}")
    print(f"\n📱 To use in CineFlow, set:")
    print(f"   LLM_MODEL={repo_id}")


def test_model(model, tokenizer):
    """Test the fine-tuned model with sample prompts."""
    print("\n🧪 Testing model...")
    
    test_prompts = [
        "What is Inception about?",
        "Recommend something like The Matrix",
        "I'm in the mood for a thriller",
    ]
    
    model.eval()
    for prompt in test_prompts:
        formatted = f"<|system|>\nYou are CineBot, a friendly movie expert.</s>\n<|user|>\n{prompt}</s>\n<|assistant|>\n"
        
        inputs = tokenizer(formatted, return_tensors="pt").to(model.device)
        outputs = model.generate(
            **inputs,
            max_new_tokens=150,
            temperature=0.7,
            do_sample=True,
            pad_token_id=tokenizer.eos_token_id,
        )
        
        response = tokenizer.decode(outputs[0], skip_special_tokens=True)
        # Extract just the assistant's response
        if "<|assistant|>" in response:
            response = response.split("<|assistant|>")[-1].strip()
        
        print(f"\n📝 Q: {prompt}")
        print(f"🤖 A: {response[:200]}...")


def main():
    """Main training pipeline."""
    print("🎬 CineBot Fine-Tuning Pipeline")
    print("=" * 50)
    
    # Check CUDA availability
    if torch.cuda.is_available():
        print(f"✅ CUDA available: {torch.cuda.get_device_name(0)}")
        print(f"   Memory: {torch.cuda.get_device_properties(0).total_memory / 1e9:.1f} GB")
    else:
        print("⚠️  No CUDA - training will be slow. Consider using Google Colab.")
    
    # Setup
    model, tokenizer = setup_model()
    model = setup_lora(model)
    dataset = load_data(tokenizer)
    
    print(f"📊 Training on {len(dataset)} examples")
    
    # Train
    trainer = train(model, tokenizer, dataset)
    
    # Test
    test_model(model, tokenizer)
    
    # Push to Hub (optional)
    push_to_hub(model, tokenizer)
    
    print("\n✅ Training complete!")
    print(f"📁 Model saved to: {OUTPUT_DIR}")


if __name__ == "__main__":
    main()
