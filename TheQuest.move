// The Quest: Wordle-like game on the Diem blockchain

// The Quest module that contains the game logic and data
module TheQuest {

    // Import necessary modules and dependencies
    import 0x1::Signer;
    import 0x1::Diem;
    import 0x1::Event;

    // Constants
    const ANSWER_LENGTH: u64 = 8;
    const ANSWER_HASH: vector<u8> = b"\x60\xc4\x00\x45\x08\xdd\xcd\x8d\x1b\x0e\xa1\xc5\x6e\xd1\xe5\x67\x9d\x75\x6d\x72\xe4\x0f\x1a\x00\x82\x0d\xbe\x5d\x9f\x69\xff\x63";
    const ATTEMPTS_LIMIT: u64 = 6;
    const PRIZE: u64 = 1000000000; // 10 APT

    // Errors
    const E_INSUFFICIENT_BALANCE: u64 = 0;
    const E_ATTEMPTS_LIMIT_REACHED: u64 = 1;
    const E_LETTER_INDEX_OUT_OF_BOUNDS: u64 = 2;
    const E_INCORRECT_WORD_LENGTH: u64 = 3;

    // Struct to store player data
    struct Player {
        attempts: vector<map<vector<u8>, bool>>,
        word_guessed: bool,
        guess_word_attempt_events: EventHandle<GuessWordAttemptEvent>,
        submit_correct_answer_events: EventHandle<SubmitCorrectAnswerEvent>,
    }

    // Event struct for a guess attempt
    struct GuessWordAttemptEvent {
        attempt: u64,
        word: vector<u8>,
        letter_correctness: map<vector<u8>, bool>,
        event_creation_timestamp_seconds: u64,
    }

    // Event struct for a correct answer submission
    struct SubmitCorrectAnswerEvent {
        attempt: u64,
        event_creation_timestamp_seconds: u64,
    }

    // Initialize player's data on account creation
    public fun create_player(player: &signer) acquires Player {
        let p = Player {
            attempts: empty,
            word_guessed: false,
            guess_word_attempt_events: Event::new(),
            submit_correct_answer_events: Event::new(),
        };
        move_to(player, p);
    }

    // Function to make a guess attempt and verify the word
    public fun guess_word(player: &signer, word: vector<u8>) acquires Player {
        // Check if the word length is correct
        check_if_word_length_is_correct(word);

        // Get the player's data
        let p = borrow_global_mut<Player>(player);

        // Check if the player has not reached the attempts limit yet
        check_if_player_has_not_reached_attempts_limit_yet(p);

        // Add the guess attempt to the player's data
        add_guess_to_attempts(p, word);

        // Check if the word is correct
        if word == ANSWER_HASH {
            // Submit the correct answer
            submit_correct_answer(p);
        } else if vector::len(p.attempts) == ATTEMPTS_LIMIT {
            // Mark word as not guessed if attempts limit is reached
            p.word_guessed = true;
        }
    }

    // Function to add a guess attempt to the player's data
    fun add_guess_to_attempts(player: &mut Player, word: vector<u8>) {
        let attempt = map<_, bool>();
        let current_time = Diem::get_block_metadata().timestamp;
        let current_attempt = vector::len(player.attempts) as u64;

        for (i, letter) in vector::enumerate(word) {
            let letter_hash = get_letter_hash(i as u64);
            let letter_correct = letter_hash == hash::sha3_256(&letter);
            attempt[letter_hash] = letter_correct;
        }

        vector::push_back(&mut player.attempts, attempt);
        player.guess_word_attempt_events.add(
            GuessWordAttemptEvent {
                attempt: current_attempt,
                word: word,
                letter_correctness: attempt,
                event_creation_timestamp_seconds: current_time,
            }
        );
    }

    // Function to submit a correct answer
    fun submit_correct_answer(player: &mut Player) {
        Diem::transfer_coin(player.guess_word_attempt_events.address(), player.guess_word_attempt_events.sequence_number(), PRIZE);
        player.word_guessed = true;
        player.submit_correct_answer_events.add(
            SubmitCorrectAnswerEvent {
                attempt: vector::len(player.attempts) as u64,
                event_creation_timestamp_seconds: Diem::get_block_metadata().timestamp,
            }
        );
    }

    // Function to get the player's guess attempts
    public fun get_guess_attempts(player: address): vector<map<vector<u8>, bool>> acquires Player {
        let p = borrow_global<Player>(player);
        p.attempts
    }

    // Function to get the hash of a letter based on the index
    fun get_letter_hash(index: u64): vector<u8> {
        // Constants for each letter's hash
        const LETTER_HASHES: vector<vector<u8>> = [
            b"\x3e\xec\xb4\xa5\xc1\x1c\x8b\xab\x18\xdd\xad\x1d\x26\x8c\x82\x7a\xaa\xbb\x17\xc8\x3f\x51\x86\x98\x32\xa5\xaf\x15\xef\xde\xdf\xcb",
            b"\xe6\x3a\x84\xc1\x84\x47\xbf\xca\x5c\x67\xb2\x0a\x58\xfc\x6a\x4f\xef\xa7\x62\xe4\xfa\x0e\x6b\x3b\x2e\x46\xf6\x4d\xab\xa3\x45\xe5",
            b"\xd0\x34\xb2\xb5\x44\xe4\xff\xb6\x19\xa9\xc1\x56\xae\x57\x8f\xe2\x1f\x38\xeb\x09\x97\xf0\x97\xca\x95\x69\x80\x7c\xa1\x57\xf4\xf6",
            b"\x69\x20\x01\x4b\xef\x53\x4e\x7e\xea\x89\x5e\xb3\x7b\x10\xe9\xb9\xd1\x3d\x21\x7d\x2f\x08\x82\x1e\x23\x2d\xab\x0b\xd8\x0e\x32\xdb",
            b"\x4c\x2c\x31\x48\x4a\x45\x05\x32\x20\x29\x1d\x1f\x9e\x1b\xbb\xfc\x9c\x25\x7a\x31\x6e\xaf\xf5\x5c\x2a\x8c\xf8\x42\x45\xca\x1d\xf3",
            b"\x31\x91\x17\x81\xd6\xe9\xf2\xd4\x7a\x90\xd3\x23\x7c\x9a\xe5\x77\x9d\xe6\x54\x46\x36\x23\x7d\x75\x32\x71\xad\xda\xd3\x6e\x4e\x3d",
            b"\x9a\xe9\x68\x1c\x92\x4c\x60\xde\x95\xf5\x8b\x7e\xb0\x5f\x35\x34\x9f\x24\x99\x71\x7e\x9c\xda\xcc\xb3\x58\x6b\xb0\xea\xf5\x7f\x45",
            b"\xd3\x31\x27\x07\x89\xca\x3f\x34\x0b\x66\x14\xd0\x59\x33\x9d\x13\x34\x21\xe2\x77\x9f\x2f\x31\x69\x75\x38\x89\x60\xeb\xda\x25\x1b",
        ];
        
        let index = index as usize;
        assert(index < vector::length(LETTER_HASHES), E_LETTER_INDEX_OUT_OF_BOUNDS);
        LETTER_HASHES[index]
    }
    
    // Function to check if the word length is correct
    fun check_if_word_length_is_correct(word: vector<u8>) {
        assert(vector::len(word) == ANSWER_LENGTH, E_INCORRECT_WORD_LENGTH);
    }

    // Function to check if the player has not reached the attempts limit yet
    fun check_if_player_has_not_reached_attempts_limit_yet(player: &Player) {
        assert(vector::len(player.attempts) < ATTEMPTS_LIMIT, E_ATTEMPTS_LIMIT_REACHED);
    }
}

