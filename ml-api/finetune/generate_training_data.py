"""
Generate training data for fine-tuning a movie chatbot LLM.

This script creates conversational training examples about movies
that can be used to fine-tune a small LLM like TinyLlama or Phi-3.

Run this to generate movie_training_data.jsonl
"""

import json
import random
from typing import List, Dict

# Movie knowledge base - 60+ popular movies for comprehensive training
MOVIES = [
    # === CLASSICS & TIMELESS ===
    {
        "title": "Inception",
        "year": 2010,
        "director": "Christopher Nolan",
        "genres": ["Sci-Fi", "Action", "Thriller"],
        "cast": ["Leonardo DiCaprio", "Joseph Gordon-Levitt", "Ellen Page", "Tom Hardy"],
        "plot": "A skilled thief who steals secrets from dreams is offered a chance at redemption: planting an idea in someone's mind instead of stealing one.",
        "themes": ["dreams", "reality vs illusion", "guilt", "redemption"],
        "similar": ["The Matrix", "Interstellar", "Shutter Island", "Tenet"]
    },
    {
        "title": "The Shawshank Redemption",
        "year": 1994,
        "director": "Frank Darabont",
        "genres": ["Drama"],
        "cast": ["Tim Robbins", "Morgan Freeman"],
        "plot": "A banker convicted of murdering his wife befriends a fellow prisoner over decades while maintaining hope and finding redemption.",
        "themes": ["hope", "friendship", "justice", "perseverance"],
        "similar": ["The Green Mile", "Forrest Gump", "The Pursuit of Happyness"]
    },
    {
        "title": "Pulp Fiction",
        "year": 1994,
        "director": "Quentin Tarantino",
        "genres": ["Crime", "Drama"],
        "cast": ["John Travolta", "Samuel L. Jackson", "Uma Thurman", "Bruce Willis"],
        "plot": "Multiple interconnected stories of criminals in Los Angeles unfold in non-linear fashion.",
        "themes": ["redemption", "fate", "violence", "pop culture"],
        "similar": ["Reservoir Dogs", "Kill Bill", "Snatch", "Lock, Stock and Two Smoking Barrels"]
    },
    {
        "title": "The Dark Knight",
        "year": 2008,
        "director": "Christopher Nolan",
        "genres": ["Action", "Crime", "Drama"],
        "cast": ["Christian Bale", "Heath Ledger", "Aaron Eckhart", "Michael Caine"],
        "plot": "Batman faces his greatest challenge when the Joker emerges as a criminal mastermind who plunges Gotham into chaos.",
        "themes": ["chaos vs order", "moral choices", "heroism", "sacrifice"],
        "similar": ["Batman Begins", "The Dark Knight Rises", "Joker", "Logan"]
    },
    {
        "title": "Interstellar",
        "year": 2014,
        "director": "Christopher Nolan",
        "genres": ["Sci-Fi", "Drama", "Adventure"],
        "cast": ["Matthew McConaughey", "Anne Hathaway", "Jessica Chastain"],
        "plot": "A team of explorers travels through a wormhole in search of a new home for humanity as Earth faces extinction.",
        "themes": ["love", "time", "survival", "sacrifice"],
        "similar": ["Gravity", "The Martian", "Arrival", "2001: A Space Odyssey"]
    },
    {
        "title": "Parasite",
        "year": 2019,
        "director": "Bong Joon-ho",
        "genres": ["Thriller", "Drama", "Comedy"],
        "cast": ["Song Kang-ho", "Lee Sun-kyun", "Cho Yeo-jeong", "Choi Woo-shik"],
        "plot": "A poor family schemes to infiltrate a wealthy household by posing as unrelated, highly qualified individuals.",
        "themes": ["class inequality", "ambition", "deception", "social commentary"],
        "similar": ["Snowpiercer", "Us", "The Host", "Shoplifters"]
    },
    {
        "title": "The Matrix",
        "year": 1999,
        "director": "The Wachowskis",
        "genres": ["Sci-Fi", "Action"],
        "cast": ["Keanu Reeves", "Laurence Fishburne", "Carrie-Anne Moss", "Hugo Weaving"],
        "plot": "A hacker discovers that reality is a simulation created by machines and joins a rebellion to free humanity.",
        "themes": ["reality", "free will", "technology", "awakening"],
        "similar": ["Inception", "The Thirteenth Floor", "Dark City", "Total Recall"]
    },
    {
        "title": "Spirited Away",
        "year": 2001,
        "director": "Hayao Miyazaki",
        "genres": ["Animation", "Fantasy", "Adventure"],
        "cast": ["Rumi Hiiragi", "Miyu Irino", "Mari Natsuki"],
        "plot": "A young girl enters a magical world of spirits and must work to free herself and her transformed parents.",
        "themes": ["coming of age", "identity", "environmentalism", "courage"],
        "similar": ["Howl's Moving Castle", "Princess Mononoke", "My Neighbor Totoro", "Ponyo"]
    },
    {
        "title": "The Godfather",
        "year": 1972,
        "director": "Francis Ford Coppola",
        "genres": ["Crime", "Drama"],
        "cast": ["Marlon Brando", "Al Pacino", "James Caan", "Robert Duvall"],
        "plot": "The aging patriarch of an organized crime dynasty transfers control to his reluctant youngest son.",
        "themes": ["family", "power", "loyalty", "corruption"],
        "similar": ["The Godfather Part II", "Goodfellas", "Scarface", "Casino"]
    },
    {
        "title": "Everything Everywhere All at Once",
        "year": 2022,
        "director": "Daniel Kwan, Daniel Scheinert",
        "genres": ["Sci-Fi", "Action", "Comedy"],
        "cast": ["Michelle Yeoh", "Stephanie Hsu", "Ke Huy Quan", "Jamie Lee Curtis"],
        "plot": "A woman discovers she can access the memories and skills of her parallel universe selves to save the multiverse.",
        "themes": ["nihilism vs meaning", "family", "identity", "generational trauma"],
        "similar": ["The Matrix", "Swiss Army Man", "Being John Malkovich", "Eternal Sunshine"]
    },
    {
        "title": "Whiplash",
        "year": 2014,
        "director": "Damien Chazelle",
        "genres": ["Drama", "Music"],
        "cast": ["Miles Teller", "J.K. Simmons"],
        "plot": "A young drummer at a music conservatory faces an abusive instructor who pushes him to his limits.",
        "themes": ["obsession", "perfection", "abuse", "ambition"],
        "similar": ["La La Land", "Black Swan", "The Pianist", "Birdman"]
    },
    {
        "title": "Get Out",
        "year": 2017,
        "director": "Jordan Peele",
        "genres": ["Horror", "Thriller", "Mystery"],
        "cast": ["Daniel Kaluuya", "Allison Williams", "Bradley Whitford", "Catherine Keener"],
        "plot": "A young Black man visits his white girlfriend's family estate and uncovers disturbing secrets.",
        "themes": ["racism", "identity", "exploitation", "paranoia"],
        "similar": ["Us", "Nope", "The Stepford Wives", "Rosemary's Baby"]
    },
    
    # === ACTION & ADVENTURE ===
    {
        "title": "Mad Max: Fury Road",
        "year": 2015,
        "director": "George Miller",
        "genres": ["Action", "Adventure", "Sci-Fi"],
        "cast": ["Tom Hardy", "Charlize Theron", "Nicholas Hoult"],
        "plot": "In a post-apocalyptic wasteland, a woman rebels against a tyrannical ruler with the help of a drifter named Max.",
        "themes": ["survival", "redemption", "freedom", "feminism"],
        "similar": ["The Road Warrior", "Fury", "Dredd", "Snowpiercer"]
    },
    {
        "title": "John Wick",
        "year": 2014,
        "director": "Chad Stahelski",
        "genres": ["Action", "Thriller"],
        "cast": ["Keanu Reeves", "Michael Nyqvist", "Alfie Allen", "Willem Dafoe"],
        "plot": "A retired hitman seeks vengeance against gangsters who killed his dog and stole his car.",
        "themes": ["revenge", "grief", "honor", "consequences"],
        "similar": ["Nobody", "The Equalizer", "Atomic Blonde", "Kill Bill"]
    },
    {
        "title": "Die Hard",
        "year": 1988,
        "director": "John McTiernan",
        "genres": ["Action", "Thriller"],
        "cast": ["Bruce Willis", "Alan Rickman", "Bonnie Bedelia"],
        "plot": "A New York cop battles terrorists who have taken hostages in a Los Angeles skyscraper during a Christmas party.",
        "themes": ["heroism", "resilience", "family"],
        "similar": ["Lethal Weapon", "Speed", "The Raid", "Under Siege"]
    },
    {
        "title": "Gladiator",
        "year": 2000,
        "director": "Ridley Scott",
        "genres": ["Action", "Drama", "Adventure"],
        "cast": ["Russell Crowe", "Joaquin Phoenix", "Connie Nielsen"],
        "plot": "A betrayed Roman general seeks revenge against the corrupt emperor who murdered his family and sent him into slavery.",
        "themes": ["revenge", "honor", "corruption", "legacy"],
        "similar": ["Braveheart", "Troy", "Kingdom of Heaven", "Spartacus"]
    },
    {
        "title": "Top Gun: Maverick",
        "year": 2022,
        "director": "Joseph Kosinski",
        "genres": ["Action", "Drama"],
        "cast": ["Tom Cruise", "Miles Teller", "Jennifer Connelly", "Jon Hamm"],
        "plot": "After thirty years, Maverick returns to train a new group of Top Gun graduates for a specialized mission.",
        "themes": ["legacy", "mentorship", "redemption", "pushing limits"],
        "similar": ["Top Gun", "The Right Stuff", "Days of Thunder", "Mission: Impossible"]
    },
    
    # === HORROR ===
    {
        "title": "The Shining",
        "year": 1980,
        "director": "Stanley Kubrick",
        "genres": ["Horror", "Drama"],
        "cast": ["Jack Nicholson", "Shelley Duvall", "Danny Lloyd"],
        "plot": "A family heads to an isolated hotel for the winter where a sinister presence influences the father into violence.",
        "themes": ["isolation", "madness", "family dysfunction", "supernatural"],
        "similar": ["Doctor Sleep", "The Haunting", "Hereditary", "1408"]
    },
    {
        "title": "Hereditary",
        "year": 2018,
        "director": "Ari Aster",
        "genres": ["Horror", "Drama", "Mystery"],
        "cast": ["Toni Collette", "Alex Wolff", "Milly Shapiro", "Gabriel Byrne"],
        "plot": "After the death of their secretive grandmother, a family begins to unravel cryptic and increasingly terrifying secrets.",
        "themes": ["grief", "family trauma", "fate", "supernatural evil"],
        "similar": ["Midsommar", "The Witch", "The Babadook", "It Follows"]
    },
    {
        "title": "A Quiet Place",
        "year": 2018,
        "director": "John Krasinski",
        "genres": ["Horror", "Sci-Fi", "Drama"],
        "cast": ["Emily Blunt", "John Krasinski", "Millicent Simmonds"],
        "plot": "A family must live in silence to avoid mysterious creatures that hunt by sound.",
        "themes": ["family protection", "survival", "sacrifice", "communication"],
        "similar": ["Bird Box", "Don't Breathe", "10 Cloverfield Lane", "The Silence"]
    },
    {
        "title": "The Conjuring",
        "year": 2013,
        "director": "James Wan",
        "genres": ["Horror", "Mystery", "Thriller"],
        "cast": ["Vera Farmiga", "Patrick Wilson", "Lili Taylor"],
        "plot": "Paranormal investigators help a family terrorized by a dark presence in their farmhouse.",
        "themes": ["faith", "evil", "family", "supernatural"],
        "similar": ["Insidious", "The Exorcist", "Annabelle", "Sinister"]
    },
    {
        "title": "It",
        "year": 2017,
        "director": "Andy Muschietti",
        "genres": ["Horror", "Fantasy"],
        "cast": ["Bill Skarsgård", "Jaeden Martell", "Finn Wolfhard"],
        "plot": "A group of kids face their biggest fears when they confront an evil clown that has emerged to terrorize their town.",
        "themes": ["childhood fears", "friendship", "courage", "trauma"],
        "similar": ["Stranger Things", "It Chapter Two", "Stand By Me", "The Goonies"]
    },
    
    # === COMEDY ===
    {
        "title": "Superbad",
        "year": 2007,
        "director": "Greg Mottola",
        "genres": ["Comedy"],
        "cast": ["Jonah Hill", "Michael Cera", "Christopher Mintz-Plasse", "Emma Stone"],
        "plot": "Two co-dependent high school seniors try to score alcohol for a party, hoping to finally hook up before graduation.",
        "themes": ["friendship", "growing up", "teenage anxiety"],
        "similar": ["Booksmart", "American Pie", "The Hangover", "Knocked Up"]
    },
    {
        "title": "The Grand Budapest Hotel",
        "year": 2014,
        "director": "Wes Anderson",
        "genres": ["Comedy", "Drama", "Adventure"],
        "cast": ["Ralph Fiennes", "Tony Revolori", "F. Murray Abraham", "Saoirse Ronan"],
        "plot": "A legendary concierge at a famous European hotel and his protégé become entangled in a murder mystery.",
        "themes": ["nostalgia", "loyalty", "adventure", "mortality"],
        "similar": ["Moonrise Kingdom", "The Royal Tenenbaums", "Knives Out", "Fantastic Mr. Fox"]
    },
    {
        "title": "The Hangover",
        "year": 2009,
        "director": "Todd Phillips",
        "genres": ["Comedy"],
        "cast": ["Bradley Cooper", "Ed Helms", "Zach Galifianakis", "Justin Bartha"],
        "plot": "Three friends wake up from a bachelor party in Las Vegas with no memory and the groom missing.",
        "themes": ["friendship", "chaos", "consequences"],
        "similar": ["Superbad", "Wedding Crashers", "Old School", "21 Jump Street"]
    },
    {
        "title": "Bridesmaids",
        "year": 2011,
        "director": "Paul Feig",
        "genres": ["Comedy", "Romance"],
        "cast": ["Kristen Wiig", "Maya Rudolph", "Rose Byrne", "Melissa McCarthy"],
        "plot": "A woman's life unravels as she leads her best friend's bridal party while competing with a wealthy newcomer.",
        "themes": ["friendship", "jealousy", "self-discovery", "growing up"],
        "similar": ["The Hangover", "Girls Trip", "Pitch Perfect", "Mean Girls"]
    },
    
    # === ROMANCE ===
    {
        "title": "La La Land",
        "year": 2016,
        "director": "Damien Chazelle",
        "genres": ["Romance", "Drama", "Musical"],
        "cast": ["Ryan Gosling", "Emma Stone"],
        "plot": "A jazz pianist and an aspiring actress fall in love while pursuing their dreams in Los Angeles.",
        "themes": ["love", "dreams", "sacrifice", "ambition"],
        "similar": ["Whiplash", "A Star Is Born", "The Notebook", "Singin' in the Rain"]
    },
    {
        "title": "The Notebook",
        "year": 2004,
        "director": "Nick Cassavetes",
        "genres": ["Romance", "Drama"],
        "cast": ["Ryan Gosling", "Rachel McAdams", "James Garner", "Gena Rowlands"],
        "plot": "A poor young man falls in love with a wealthy girl, but their romance is threatened by class differences and war.",
        "themes": ["eternal love", "class", "memory", "devotion"],
        "similar": ["A Walk to Remember", "The Fault in Our Stars", "Me Before You", "Titanic"]
    },
    {
        "title": "Pride and Prejudice",
        "year": 2005,
        "director": "Joe Wright",
        "genres": ["Romance", "Drama"],
        "cast": ["Keira Knightley", "Matthew Macfadyen", "Judi Dench"],
        "plot": "A spirited young woman and a wealthy but proud gentleman overcome their mutual dislike to find love.",
        "themes": ["love", "class", "pride", "personal growth"],
        "similar": ["Sense and Sensibility", "Emma", "Atonement", "Jane Eyre"]
    },
    {
        "title": "Crazy Rich Asians",
        "year": 2018,
        "director": "Jon M. Chu",
        "genres": ["Romance", "Comedy", "Drama"],
        "cast": ["Constance Wu", "Henry Golding", "Michelle Yeoh", "Gemma Chan"],
        "plot": "A woman discovers her boyfriend is from one of the wealthiest families in Singapore when she meets his family.",
        "themes": ["family expectations", "cultural identity", "love", "wealth"],
        "similar": ["The Proposal", "Bride Wars", "Always Be My Maybe", "To All the Boys I've Loved Before"]
    },
    
    # === SCI-FI ===
    {
        "title": "Blade Runner 2049",
        "year": 2017,
        "director": "Denis Villeneuve",
        "genres": ["Sci-Fi", "Drama", "Mystery"],
        "cast": ["Ryan Gosling", "Harrison Ford", "Ana de Armas", "Jared Leto"],
        "plot": "A blade runner uncovers a secret that threatens to plunge society into chaos and his discovery leads him to a man who has been missing for thirty years.",
        "themes": ["identity", "humanity", "memory", "existence"],
        "similar": ["Blade Runner", "Ex Machina", "Ghost in the Shell", "Minority Report"]
    },
    {
        "title": "Dune",
        "year": 2021,
        "director": "Denis Villeneuve",
        "genres": ["Sci-Fi", "Adventure", "Drama"],
        "cast": ["Timothée Chalamet", "Rebecca Ferguson", "Zendaya", "Oscar Isaac"],
        "plot": "A noble family must navigate political treachery on a desert planet that holds the most valuable resource in the universe.",
        "themes": ["destiny", "power", "ecology", "religion"],
        "similar": ["Dune: Part Two", "Star Wars", "Blade Runner 2049", "Foundation"]
    },
    {
        "title": "Arrival",
        "year": 2016,
        "director": "Denis Villeneuve",
        "genres": ["Sci-Fi", "Drama", "Mystery"],
        "cast": ["Amy Adams", "Jeremy Renner", "Forest Whitaker"],
        "plot": "A linguist is recruited to communicate with aliens who have landed on Earth, leading to a profound discovery about time and choice.",
        "themes": ["communication", "time", "grief", "choice"],
        "similar": ["Interstellar", "Contact", "Close Encounters", "Annihilation"]
    },
    {
        "title": "Ex Machina",
        "year": 2014,
        "director": "Alex Garland",
        "genres": ["Sci-Fi", "Drama", "Thriller"],
        "cast": ["Alicia Vikander", "Domhnall Gleeson", "Oscar Isaac"],
        "plot": "A programmer is selected to participate in a groundbreaking experiment in artificial intelligence by evaluating a humanoid AI.",
        "themes": ["consciousness", "manipulation", "humanity", "ethics"],
        "similar": ["Her", "Blade Runner 2049", "Annihilation", "The Machine"]
    },
    {
        "title": "The Martian",
        "year": 2015,
        "director": "Ridley Scott",
        "genres": ["Sci-Fi", "Drama", "Adventure"],
        "cast": ["Matt Damon", "Jessica Chastain", "Kristen Wiig", "Jeff Daniels"],
        "plot": "An astronaut is stranded on Mars and must use his ingenuity to survive while NASA works to bring him home.",
        "themes": ["survival", "ingenuity", "hope", "teamwork"],
        "similar": ["Interstellar", "Gravity", "Apollo 13", "Cast Away"]
    },
    {
        "title": "Avatar",
        "year": 2009,
        "director": "James Cameron",
        "genres": ["Sci-Fi", "Action", "Adventure"],
        "cast": ["Sam Worthington", "Zoe Saldana", "Sigourney Weaver", "Stephen Lang"],
        "plot": "A paraplegic Marine is sent to the moon Pandora where he becomes torn between following orders and protecting the world he feels is his home.",
        "themes": ["environmentalism", "colonialism", "identity", "nature"],
        "similar": ["Avatar: The Way of Water", "Dances with Wolves", "District 9", "Aliens"]
    },
    
    # === THRILLER & SUSPENSE ===
    {
        "title": "Se7en",
        "year": 1995,
        "director": "David Fincher",
        "genres": ["Thriller", "Crime", "Mystery"],
        "cast": ["Brad Pitt", "Morgan Freeman", "Kevin Spacey", "Gwyneth Paltrow"],
        "plot": "Two detectives hunt a serial killer who uses the seven deadly sins as motifs for his murders.",
        "themes": ["sin", "justice", "nihilism", "morality"],
        "similar": ["Zodiac", "The Silence of the Lambs", "Prisoners", "Gone Girl"]
    },
    {
        "title": "Gone Girl",
        "year": 2014,
        "director": "David Fincher",
        "genres": ["Thriller", "Drama", "Mystery"],
        "cast": ["Ben Affleck", "Rosamund Pike", "Neil Patrick Harris"],
        "plot": "A man becomes the prime suspect in his wife's disappearance, but nothing is as it seems.",
        "themes": ["marriage", "media manipulation", "deception", "identity"],
        "similar": ["The Girl on the Train", "Sharp Objects", "Prisoners", "Se7en"]
    },
    {
        "title": "Prisoners",
        "year": 2013,
        "director": "Denis Villeneuve",
        "genres": ["Thriller", "Drama", "Crime"],
        "cast": ["Hugh Jackman", "Jake Gyllenhaal", "Viola Davis", "Paul Dano"],
        "plot": "When his daughter goes missing, a desperate father takes matters into his own hands while a detective races to solve the case.",
        "themes": ["morality", "justice", "desperation", "faith"],
        "similar": ["Zodiac", "Mystic River", "Gone Girl", "Se7en"]
    },
    {
        "title": "Shutter Island",
        "year": 2010,
        "director": "Martin Scorsese",
        "genres": ["Thriller", "Mystery", "Drama"],
        "cast": ["Leonardo DiCaprio", "Mark Ruffalo", "Ben Kingsley"],
        "plot": "A U.S. Marshal investigates a psychiatric facility on an island after a patient goes missing, uncovering a dark conspiracy.",
        "themes": ["trauma", "reality", "guilt", "identity"],
        "similar": ["Inception", "The Sixth Sense", "Memento", "The Machinist"]
    },
    {
        "title": "The Silence of the Lambs",
        "year": 1991,
        "director": "Jonathan Demme",
        "genres": ["Thriller", "Crime", "Drama"],
        "cast": ["Jodie Foster", "Anthony Hopkins", "Scott Glenn"],
        "plot": "An FBI trainee must receive the help of an incarcerated cannibal killer to catch another serial killer.",
        "themes": ["evil", "manipulation", "identity", "courage"],
        "similar": ["Hannibal", "Se7en", "Red Dragon", "Zodiac"]
    },
    
    # === DRAMA ===
    {
        "title": "Forrest Gump",
        "year": 1994,
        "director": "Robert Zemeckis",
        "genres": ["Drama", "Romance"],
        "cast": ["Tom Hanks", "Robin Wright", "Gary Sinise", "Sally Field"],
        "plot": "A man with a low IQ has accomplished great things in his life and witnesses key historical events, all while pursuing his true love.",
        "themes": ["destiny", "love", "innocence", "American history"],
        "similar": ["The Shawshank Redemption", "Cast Away", "Big Fish", "The Green Mile"]
    },
    {
        "title": "The Pursuit of Happyness",
        "year": 2006,
        "director": "Gabriele Muccino",
        "genres": ["Drama", "Biography"],
        "cast": ["Will Smith", "Jaden Smith", "Thandiwe Newton"],
        "plot": "A struggling salesman takes custody of his son as he tries to build a better life through an unpaid internship at a stock brokerage.",
        "themes": ["perseverance", "fatherhood", "hope", "hard work"],
        "similar": ["The Shawshank Redemption", "Slumdog Millionaire", "Hidden Figures", "The Blind Side"]
    },
    {
        "title": "The Green Mile",
        "year": 1999,
        "director": "Frank Darabont",
        "genres": ["Drama", "Fantasy", "Crime"],
        "cast": ["Tom Hanks", "Michael Clarke Duncan", "David Morse"],
        "plot": "A death row corrections officer discovers that one of his inmates has a mysterious gift and is innocent of his crime.",
        "themes": ["innocence", "miracles", "humanity", "justice"],
        "similar": ["The Shawshank Redemption", "Forrest Gump", "Dead Man Walking", "The Curious Case of Benjamin Button"]
    },
    {
        "title": "12 Years a Slave",
        "year": 2013,
        "director": "Steve McQueen",
        "genres": ["Drama", "Biography", "History"],
        "cast": ["Chiwetel Ejiofor", "Michael Fassbender", "Lupita Nyong'o"],
        "plot": "A free Black man is kidnapped and sold into slavery, enduring twelve years of brutality before finding a chance for freedom.",
        "themes": ["freedom", "survival", "humanity", "injustice"],
        "similar": ["Django Unchained", "Selma", "The Color Purple", "Roots"]
    },
    {
        "title": "Good Will Hunting",
        "year": 1997,
        "director": "Gus Van Sant",
        "genres": ["Drama", "Romance"],
        "cast": ["Matt Damon", "Robin Williams", "Ben Affleck", "Minnie Driver"],
        "plot": "A janitor at MIT has a gift for mathematics, but needs help from a therapist to overcome his troubled past.",
        "themes": ["potential", "trauma", "friendship", "self-discovery"],
        "similar": ["A Beautiful Mind", "Dead Poets Society", "The Perks of Being a Wallflower", "Finding Forrester"]
    },
    {
        "title": "Fight Club",
        "year": 1999,
        "director": "David Fincher",
        "genres": ["Drama", "Thriller"],
        "cast": ["Brad Pitt", "Edward Norton", "Helena Bonham Carter"],
        "plot": "An insomniac office worker and a soap salesman build a global organization for men who want to break free from modern life.",
        "themes": ["identity", "consumerism", "masculinity", "anarchy"],
        "similar": ["American Psycho", "The Machinist", "Mr. Robot", "Taxi Driver"]
    },
    {
        "title": "Schindler's List",
        "year": 1993,
        "director": "Steven Spielberg",
        "genres": ["Drama", "History", "Biography"],
        "cast": ["Liam Neeson", "Ben Kingsley", "Ralph Fiennes"],
        "plot": "A German businessman saves over a thousand Jewish refugees during the Holocaust by employing them in his factories.",
        "themes": ["humanity", "redemption", "courage", "evil"],
        "similar": ["The Pianist", "Life Is Beautiful", "12 Years a Slave", "The Boy in the Striped Pajamas"]
    },
    
    # === SUPERHERO & COMIC BOOK ===
    {
        "title": "Spider-Man: Into the Spider-Verse",
        "year": 2018,
        "director": "Bob Persichetti, Peter Ramsey, Rodney Rothman",
        "genres": ["Animation", "Action", "Adventure"],
        "cast": ["Shameik Moore", "Jake Johnson", "Hailee Steinfeld"],
        "plot": "Teen Miles Morales becomes Spider-Man and must team up with Spider-People from other dimensions to stop a threat to all realities.",
        "themes": ["identity", "heroism", "family", "destiny"],
        "similar": ["Spider-Man: Across the Spider-Verse", "The Incredibles", "Big Hero 6", "Teen Titans Go! To the Movies"]
    },
    {
        "title": "Joker",
        "year": 2019,
        "director": "Todd Phillips",
        "genres": ["Drama", "Crime", "Thriller"],
        "cast": ["Joaquin Phoenix", "Robert De Niro", "Zazie Beetz"],
        "plot": "A failed comedian's descent into madness transforms him into the criminal mastermind known as the Joker.",
        "themes": ["mental illness", "society", "isolation", "identity"],
        "similar": ["The Dark Knight", "Taxi Driver", "The King of Comedy", "Nightcrawler"]
    },
    {
        "title": "Logan",
        "year": 2017,
        "director": "James Mangold",
        "genres": ["Action", "Drama", "Sci-Fi"],
        "cast": ["Hugh Jackman", "Patrick Stewart", "Dafne Keen"],
        "plot": "In a dark future, a weary Logan cares for an ailing Professor X while protecting a young mutant girl from dark forces.",
        "themes": ["mortality", "legacy", "fatherhood", "redemption"],
        "similar": ["The Dark Knight", "Joker", "The Wolverine", "Children of Men"]
    },
    {
        "title": "The Avengers",
        "year": 2012,
        "director": "Joss Whedon",
        "genres": ["Action", "Adventure", "Sci-Fi"],
        "cast": ["Robert Downey Jr.", "Chris Evans", "Scarlett Johansson", "Chris Hemsworth"],
        "plot": "Earth's mightiest heroes must come together to stop Loki and his alien army from enslaving humanity.",
        "themes": ["teamwork", "heroism", "sacrifice", "unity"],
        "similar": ["Avengers: Endgame", "Justice League", "Guardians of the Galaxy", "Captain America: Civil War"]
    },
    {
        "title": "Black Panther",
        "year": 2018,
        "director": "Ryan Coogler",
        "genres": ["Action", "Adventure", "Sci-Fi"],
        "cast": ["Chadwick Boseman", "Michael B. Jordan", "Lupita Nyong'o", "Danai Gurira"],
        "plot": "T'Challa returns home to the isolated nation of Wakanda to take his place as King, but a challenger threatens to destroy everything.",
        "themes": ["heritage", "responsibility", "colonialism", "identity"],
        "similar": ["Thor: Ragnarok", "Captain America: Civil War", "Wakanda Forever", "Creed"]
    },
    
    # === ANIMATED ===
    {
        "title": "Coco",
        "year": 2017,
        "director": "Lee Unkrich, Adrian Molina",
        "genres": ["Animation", "Adventure", "Family"],
        "cast": ["Anthony Gonzalez", "Gael García Bernal", "Benjamin Bratt"],
        "plot": "A boy who dreams of being a musician enters the Land of the Dead to find his great-great-grandfather, a legendary singer.",
        "themes": ["family", "memory", "following dreams", "death"],
        "similar": ["The Book of Life", "Soul", "Encanto", "Up"]
    },
    {
        "title": "Up",
        "year": 2009,
        "director": "Pete Docter, Bob Peterson",
        "genres": ["Animation", "Adventure", "Comedy"],
        "cast": ["Ed Asner", "Jordan Nagai", "Christopher Plummer"],
        "plot": "An elderly widower fulfills his dream of adventure by tying thousands of balloons to his house and flying to South America.",
        "themes": ["adventure", "grief", "friendship", "letting go"],
        "similar": ["Wall-E", "Coco", "Inside Out", "Finding Nemo"]
    },
    {
        "title": "Inside Out",
        "year": 2015,
        "director": "Pete Docter, Ronnie del Carmen",
        "genres": ["Animation", "Comedy", "Drama"],
        "cast": ["Amy Poehler", "Phyllis Smith", "Bill Hader", "Lewis Black"],
        "plot": "Inside a young girl's mind, five emotions try to lead her through a difficult life transition.",
        "themes": ["emotions", "growing up", "memory", "change"],
        "similar": ["Soul", "Up", "Coco", "Inside Out 2"]
    },
    {
        "title": "Toy Story",
        "year": 1995,
        "director": "John Lasseter",
        "genres": ["Animation", "Adventure", "Comedy"],
        "cast": ["Tom Hanks", "Tim Allen", "Don Rickles", "Jim Varney"],
        "plot": "A cowboy doll is profoundly threatened when a new spaceman figure supplants him as top toy in a boy's room.",
        "themes": ["friendship", "jealousy", "belonging", "loyalty"],
        "similar": ["Toy Story 2", "Toy Story 3", "A Bug's Life", "Monsters, Inc."]
    },
    {
        "title": "Finding Nemo",
        "year": 2003,
        "director": "Andrew Stanton, Lee Unkrich",
        "genres": ["Animation", "Adventure", "Comedy"],
        "cast": ["Albert Brooks", "Ellen DeGeneres", "Alexander Gould"],
        "plot": "An overprotective clownfish embarks on a journey to find his son who was captured by a scuba diver.",
        "themes": ["parenthood", "overprotection", "courage", "letting go"],
        "similar": ["Finding Dory", "The Incredibles", "Monsters, Inc.", "Up"]
    },
    
    # === INTERNATIONAL & FOREIGN LANGUAGE ===
    {
        "title": "Amélie",
        "year": 2001,
        "director": "Jean-Pierre Jeunet",
        "genres": ["Comedy", "Romance"],
        "cast": ["Audrey Tautou", "Mathieu Kassovitz", "Rufus"],
        "plot": "A shy Parisian waitress decides to change the lives of those around her for the better while struggling with her own isolation.",
        "themes": ["kindness", "loneliness", "love", "imagination"],
        "similar": ["The Grand Budapest Hotel", "Midnight in Paris", "Cinema Paradiso", "Delicatessen"]
    },
    {
        "title": "Oldboy",
        "year": 2003,
        "director": "Park Chan-wook",
        "genres": ["Action", "Drama", "Mystery"],
        "cast": ["Choi Min-sik", "Yoo Ji-tae", "Kang Hye-jung"],
        "plot": "After being kidnapped and imprisoned for fifteen years, a man is released and seeks vengeance on his captor.",
        "themes": ["revenge", "mystery", "obsession", "fate"],
        "similar": ["I Saw the Devil", "The Handmaiden", "Sympathy for Mr. Vengeance", "Prisoners"]
    },
    {
        "title": "Your Name",
        "year": 2016,
        "director": "Makoto Shinkai",
        "genres": ["Animation", "Drama", "Fantasy"],
        "cast": ["Ryunosuke Kamiki", "Mone Kamishiraishi"],
        "plot": "Two teenagers discover they are mysteriously swapping bodies and form a connection across time and space.",
        "themes": ["connection", "fate", "time", "love"],
        "similar": ["Weathering with You", "A Silent Voice", "The Garden of Words", "5 Centimeters Per Second"]
    },
    {
        "title": "City of God",
        "year": 2002,
        "director": "Fernando Meirelles, Kátia Lund",
        "genres": ["Crime", "Drama"],
        "cast": ["Alexandre Rodrigues", "Leandro Firmino", "Phellipe Haagensen"],
        "plot": "Two boys growing up in a violent neighborhood of Rio de Janeiro take different paths: one becomes a photographer, the other a drug dealer.",
        "themes": ["poverty", "violence", "choices", "survival"],
        "similar": ["Slumdog Millionaire", "Elite Squad", "Amores Perros", "Trainspotting"]
    },
    {
        "title": "Pan's Labyrinth",
        "year": 2006,
        "director": "Guillermo del Toro",
        "genres": ["Drama", "Fantasy", "War"],
        "cast": ["Ivana Baquero", "Sergi López", "Doug Jones"],
        "plot": "In post-Civil War Spain, a girl discovers a labyrinth and meets a faun who sets her on a path to discover her true destiny.",
        "themes": ["innocence", "fascism", "fantasy vs reality", "disobedience"],
        "similar": ["The Shape of Water", "The Devil's Backbone", "Crimson Peak", "MirrorMask"]
    },
    
    # === RECENT HITS (2020s) ===
    {
        "title": "Oppenheimer",
        "year": 2023,
        "director": "Christopher Nolan",
        "genres": ["Drama", "Biography", "History"],
        "cast": ["Cillian Murphy", "Emily Blunt", "Matt Damon", "Robert Downey Jr."],
        "plot": "The story of physicist J. Robert Oppenheimer and his role in developing the atomic bomb during World War II.",
        "themes": ["responsibility", "morality", "genius", "consequences"],
        "similar": ["A Beautiful Mind", "The Imitation Game", "First Man", "Darkest Hour"]
    },
    {
        "title": "Barbie",
        "year": 2023,
        "director": "Greta Gerwig",
        "genres": ["Comedy", "Adventure", "Fantasy"],
        "cast": ["Margot Robbie", "Ryan Gosling", "America Ferrera", "Will Ferrell"],
        "plot": "Barbie and Ken leave the perfect world of Barbieland to discover themselves in the real world.",
        "themes": ["identity", "feminism", "self-discovery", "existentialism"],
        "similar": ["Legally Blonde", "The Truman Show", "Enchanted", "Clueless"]
    },
    {
        "title": "The Batman",
        "year": 2022,
        "director": "Matt Reeves",
        "genres": ["Action", "Crime", "Drama"],
        "cast": ["Robert Pattinson", "Zoë Kravitz", "Paul Dano", "Colin Farrell"],
        "plot": "Batman ventures into Gotham's underworld when a sadistic killer leaves a trail of cryptic clues.",
        "themes": ["vengeance", "corruption", "identity", "justice"],
        "similar": ["The Dark Knight", "Joker", "Se7en", "Zodiac"]
    },
    {
        "title": "No Time to Die",
        "year": 2021,
        "director": "Cary Joji Fukunaga",
        "genres": ["Action", "Adventure", "Thriller"],
        "cast": ["Daniel Craig", "Rami Malek", "Léa Seydoux", "Ana de Armas"],
        "plot": "James Bond comes out of retirement to face a dangerous new villain armed with a mysterious technology.",
        "themes": ["legacy", "sacrifice", "love", "time"],
        "similar": ["Skyfall", "Casino Royale", "Mission: Impossible", "The Bourne Ultimatum"]
    },
    {
        "title": "The Power of the Dog",
        "year": 2021,
        "director": "Jane Campion",
        "genres": ["Drama", "Western"],
        "cast": ["Benedict Cumberbatch", "Kirsten Dunst", "Jesse Plemons", "Kodi Smit-McPhee"],
        "plot": "A domineering rancher responds with cruelty when his brother brings home a new wife and her son.",
        "themes": ["masculinity", "repression", "cruelty", "hidden depths"],
        "similar": ["There Will Be Blood", "No Country for Old Men", "Brokeback Mountain", "Phantom Thread"]
    },
]

# Template categories for training examples
TEMPLATES = {
    "what_is_about": [
        ("What is {title} about?", "**{title}** ({year}) is directed by {director}. {plot} It stars {cast_str} and explores themes of {themes_str}. If you enjoyed it, you might also like {similar_str}."),
        ("Tell me about {title}", "{title} is a {year} {genres_str} film by {director}. {plot} The movie features {cast_str} and deals with themes like {themes_str}."),
        ("Can you describe {title}?", "Sure! {title} ({year}) is a {genres_str} directed by {director}. {plot} It stars {cast_str}."),
    ],
    "recommendations": [
        ("I liked {title}, what else should I watch?", "If you enjoyed {title}, I'd recommend {similar_str}! These films share similar themes of {themes_str}. They're all great {genres_str} films."),
        ("What movies are similar to {title}?", "Movies similar to {title} include {similar_str}. They all explore themes like {themes_str} and are great picks for {genres_str} fans."),
        ("Recommend something like {title}", "Based on {title}, you'd probably enjoy {similar_str}. They share the {genres_str} vibe and themes of {themes_str}."),
    ],
    "director_info": [
        ("Who directed {title}?", "{title} was directed by {director}. They created a masterful {genres_str} film in {year}."),
        ("Tell me about {director}'s movies", "{director} directed {title} ({year}), a notable {genres_str} film. They're known for {themes_str} themes."),
    ],
    "cast_info": [
        ("Who stars in {title}?", "{title} features {cast_str}. It's a {year} {genres_str} directed by {director}."),
        ("Who is in the cast of {title}?", "The cast of {title} includes {cast_str}. The {year} film was directed by {director}."),
    ],
    "genre_recommendations": [
        ("What's a good {genre} movie?", "For {genre}, I'd recommend {title} ({year}) directed by {director}. {plot}"),
        ("Recommend a {genre} film", "Check out {title}! It's an excellent {year} {genre} film by {director}. {plot}"),
        ("I'm in the mood for {genre}", "You should watch {title} ({year})! {plot} It's one of the best {genre} films."),
    ],
    "comparisons": [
        ("Should I watch {title} or {similar_0}?", "Both are excellent! {title} focuses on {themes_str} while {similar_0} has its own unique take. {title} is directed by {director} ({year}), and I'd say start there if you haven't seen either."),
    ],
    "general_questions": [
        ("What are the best movies of all time?", "Some all-time greats include The Shawshank Redemption, The Godfather, Pulp Fiction, and The Dark Knight. For modern classics, check out Parasite and Everything Everywhere All at Once!"),
        ("What should I watch tonight?", "What genre are you in the mood for? For action, try The Dark Knight or The Matrix. For drama, The Shawshank Redemption is timeless. For something unique, Everything Everywhere All at Once is fantastic!"),
        ("What's trending right now?", "I'd recommend checking out recent acclaimed films like Everything Everywhere All at Once, Parasite, or Get Out. They're all critically loved and offer unique viewing experiences!"),
    ],
}


def format_movie_data(movie: Dict) -> Dict:
    """Convert movie dict to formatted strings."""
    return {
        **movie,
        "cast_str": ", ".join(movie["cast"][:3]),
        "genres_str": "/".join(movie["genres"]),
        "themes_str": ", ".join(movie["themes"][:3]),
        "similar_str": ", ".join(movie["similar"][:3]),
        "similar_0": movie["similar"][0] if movie["similar"] else "",
        "genre": random.choice(movie["genres"]),
    }


def generate_examples() -> List[Dict]:
    """Generate training examples from templates and movie data."""
    examples = []
    
    for movie in MOVIES:
        data = format_movie_data(movie)
        
        # Generate examples from each template category
        for category, templates in TEMPLATES.items():
            if category == "general_questions":
                continue  # Handle separately
            
            for prompt_template, response_template in templates:
                try:
                    prompt = prompt_template.format(**data)
                    response = response_template.format(**data)
                    examples.append({
                        "instruction": prompt,
                        "response": response,
                    })
                except KeyError:
                    continue
    
    # Add general questions
    for prompt, response in TEMPLATES["general_questions"]:
        examples.append({
            "instruction": prompt,
            "response": response,
        })
    
    # Add some variations with different phrasings
    variations = [
        ("Can you help me find a movie?", "Of course! Tell me what genre you're in the mood for, or mention a movie you've enjoyed recently and I'll suggest similar ones."),
        ("I don't know what to watch", "No problem! Are you looking for something relaxing, exciting, or thought-provoking? Give me a hint about your mood and I'll find the perfect film."),
        ("Who are you?", "I'm CineBot, your movie expert assistant! I can recommend films, answer questions about movies, actors, and directors, and help you decide what to watch next."),
        ("What can you do?", "I can help you with movie recommendations, answer questions about films and filmmakers, explain plots and themes, and suggest what to watch based on your preferences!"),
    ]
    
    for prompt, response in variations:
        examples.append({"instruction": prompt, "response": response})
    
    return examples


def save_training_data(examples: List[Dict], filename: str = "movie_training_data.jsonl"):
    """Save training data in JSONL format."""
    with open(filename, "w") as f:
        for example in examples:
            f.write(json.dumps(example) + "\n")
    print(f"✅ Saved {len(examples)} training examples to {filename}")


def save_chat_format(examples: List[Dict], filename: str = "movie_training_chat.jsonl"):
    """Save in chat/conversation format for instruction-tuned models."""
    with open(filename, "w") as f:
        for example in examples:
            chat_example = {
                "messages": [
                    {"role": "system", "content": "You are CineBot, a friendly and knowledgeable movie expert assistant."},
                    {"role": "user", "content": example["instruction"]},
                    {"role": "assistant", "content": example["response"]}
                ]
            }
            f.write(json.dumps(chat_example) + "\n")
    print(f"✅ Saved {len(examples)} chat examples to {filename}")


if __name__ == "__main__":
    print("🎬 Generating movie training data...")
    
    examples = generate_examples()
    random.shuffle(examples)
    
    # Save in both formats
    save_training_data(examples, "movie_training_data.jsonl")
    save_chat_format(examples, "movie_training_chat.jsonl")
    
    print(f"\n📊 Generated {len(examples)} training examples")
    print("\n📝 Sample examples:")
    for ex in examples[:3]:
        print(f"\nQ: {ex['instruction']}")
        print(f"A: {ex['response'][:100]}...")
