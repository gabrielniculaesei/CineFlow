# CineBot Fine-Tuning

Fine-tune a small LLM to become a movie expert for CineFlow.

## Quick Start with Google Colab

Easiest option, no local GPU needed.

1. Open finetune_colab.ipynb in Google Colab
2. Set your Hugging Face username in the config cell
3. Run all cells (takes about 30-45 min on free T4 GPU)
4. Your model gets uploaded to Hugging Face automatically

## Local Training

If you have a GPU with 8GB+ VRAM:

```bash
cd finetune
pip install -r requirements.txt

# Generate training data
python generate_training_data.py

# Fine-tune (requires GPU)
python finetune_tinyllama.py
```

## Files

| File | Purpose |
|------|---------|
| finetune_colab.ipynb | Complete training notebook for Colab |
| generate_training_data.py | Create movie Q&A training examples |
| finetune_tinyllama.py | Local training script |
| requirements.txt | Training dependencies |

## Training Data Format

The generate_training_data.py script creates examples like:

```
Q: What is Inception about?
A: Inception (2010) is directed by Christopher Nolan. A skilled thief who 
   steals secrets from dreams is offered a chance at redemption...

Q: I liked The Matrix, what else should I watch?
A: If you enjoyed The Matrix, I'd recommend Inception, Dark City...
```

To add more movies, edit the MOVIES list in generate_training_data.py.

## Using Your Fine-Tuned Model

After training, update your CineFlow deployment environment variables:

```
LLM_PROVIDER=huggingface
LLM_MODEL=your-username/cinebot-movie-expert
HF_API_TOKEN=hf_xxxxx
```

## Cost

| Method | Cost | Time |
|--------|------|------|
| Google Colab (T4) | Free | 45 min |
| Local GPU (8GB) | Free | 30 min |
| Hugging Face AutoTrain | $5-20 | 1-2 hours |

## Tips

- More training data gives better results
- TinyLlama (1.1B parameters) balances quality and speed well
- LoRA makes training efficient, only trains about 1% of parameters
- Test your model before deploying
