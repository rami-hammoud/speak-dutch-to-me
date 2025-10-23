#!/usr/bin/env python3
"""
Load seed vocabulary data into the Dutch Learning database
"""

import sqlite3
import json
import sys
from pathlib import Path

def load_seed_vocabulary(db_path: str, seed_file: str):
    """Load seed vocabulary from JSON file into database"""
    
    # Load JSON data
    with open(seed_file, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    # Check if vocabulary already exists
    cursor.execute("SELECT COUNT(*) FROM vocabulary")
    existing_count = cursor.fetchone()[0]
    
    if existing_count > 0:
        print(f"Database already contains {existing_count} words.")
        response = input("Do you want to add more words? (y/n): ")
        if response.lower() != 'y':
            print("Aborted.")
            conn.close()
            return
    
    # Insert vocabulary
    added = 0
    for word in data['vocabulary']:
        try:
            cursor.execute('''
                INSERT INTO vocabulary 
                (dutch_word, english_translation, category, level, pronunciation, example_sentence, mastery_score)
                VALUES (?, ?, ?, ?, ?, ?, ?)
            ''', (
                word['dutch'],
                word['english'],
                word['category'],
                word['level'],
                word['pronunciation'],
                word['example'],
                0.0
            ))
            added += 1
        except sqlite3.IntegrityError:
            print(f"Word '{word['dutch']}' already exists, skipping...")
            continue
    
    conn.commit()
    conn.close()
    
    print(f"\n✅ Successfully added {added} words to the database!")
    print(f"📚 Total vocabulary: {existing_count + added} words")

if __name__ == "__main__":
    # Default paths
    db_path = Path(__file__).parent / "data" / "dutch_learning.db"
    seed_file = Path(__file__).parent / "data" / "seed_vocabulary.json"
    
    # Allow custom paths from command line
    if len(sys.argv) > 1:
        db_path = Path(sys.argv[1])
    if len(sys.argv) > 2:
        seed_file = Path(sys.argv[2])
    
    print(f"Database: {db_path}")
    print(f"Seed file: {seed_file}")
    
    if not seed_file.exists():
        print(f"❌ Error: Seed file not found at {seed_file}")
        sys.exit(1)
    
    # Ensure database directory exists
    db_path.parent.mkdir(parents=True, exist_ok=True)
    
    # Initialize database if it doesn't exist
    if not db_path.exists():
        print("Creating new database...")
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        
        # Create vocabulary table
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS vocabulary (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                dutch_word TEXT NOT NULL,
                english_translation TEXT NOT NULL,
                category TEXT,
                level TEXT,
                pronunciation TEXT,
                example_sentence TEXT,
                added_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                last_reviewed TIMESTAMP,
                review_count INTEGER DEFAULT 0,
                mastery_score REAL DEFAULT 0.0
            )
        ''')
        
        # Create other tables
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS practice_sessions (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                session_type TEXT,
                start_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                end_time TIMESTAMP,
                words_practiced INTEGER DEFAULT 0,
                correct_answers INTEGER DEFAULT 0,
                level TEXT
            )
        ''')
        
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS daily_progress (
                date DATE PRIMARY KEY,
                words_learned INTEGER DEFAULT 0,
                words_reviewed INTEGER DEFAULT 0,
                time_spent_minutes INTEGER DEFAULT 0,
                exercises_completed INTEGER DEFAULT 0,
                streak_day INTEGER DEFAULT 0
            )
        ''')
        
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS grammar_progress (
                topic TEXT PRIMARY KEY,
                mastery_level REAL DEFAULT 0.0,
                last_practiced TIMESTAMP,
                exercises_completed INTEGER DEFAULT 0
            )
        ''')
        
        conn.commit()
        conn.close()
        print("✅ Database initialized")
    
    load_seed_vocabulary(str(db_path), str(seed_file))
