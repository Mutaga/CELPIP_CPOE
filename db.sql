-- USERS
CREATE TABLE users (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    full_name VARCHAR(150) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role ENUM('student','teacher','admin') DEFAULT 'student',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- TESTS (per skill)
CREATE TABLE celpip_tests (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(50) NOT NULL UNIQUE,          -- e.g. CEL-L1, CEL-R1, CEL-W1, CEL-S1
    skill ENUM('listening','reading','writing','speaking') NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    level VARCHAR(50),                         -- e.g. "General"
    estimated_minutes TINYINT UNSIGNED,
    is_active TINYINT(1) DEFAULT 1,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- SECTIONS WITHIN A TEST
CREATE TABLE celpip_sections (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    test_id INT UNSIGNED NOT NULL,
    section_number TINYINT UNSIGNED NOT NULL, -- 1..6 listening, 1..4 reading, etc.
    section_type VARCHAR(50) NOT NULL,        -- e.g. problem_solving, correspondence
    title VARCHAR(255),
    instructions TEXT,
    audio_file VARCHAR(255),                  -- for listening
    image_file VARCHAR(255),                  -- for diagrams / speaking images
    duration_seconds INT UNSIGNED,            -- optional per section timer
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (test_id) REFERENCES celpip_tests(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- QUESTIONS (Listening + Reading primarily)
CREATE TABLE celpip_questions (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    section_id INT UNSIGNED NOT NULL,
    question_number TINYINT UNSIGNED NOT NULL,
    question_type ENUM('mcq_single','mcq_multiple','gap_fill','match','true_false') NOT NULL,
    question_text TEXT NOT NULL,
    extra_text TEXT,                          -- small passage or email line etc.
    image_file VARCHAR(255),                  -- for diagrams / scenes if needed
    options_json JSON,                        -- ["A....","B...."] etc.
    correct_answer VARCHAR(255),              -- "A", "B", "A|C" or exact word for gap fill
    points DECIMAL(4,2) DEFAULT 1.0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (section_id) REFERENCES celpip_sections(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- WRITING PROMPTS (can also be stored as sections, but this is simpler)
CREATE TABLE celpip_writing_tasks (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    test_id INT UNSIGNED NOT NULL,
    task_number TINYINT UNSIGNED NOT NULL, -- 1 email, 2 survey
    prompt_title VARCHAR(255) NOT NULL,
    prompt_text TEXT NOT NULL,
    suggested_word_min SMALLINT UNSIGNED DEFAULT 150,
    suggested_word_max SMALLINT UNSIGNED DEFAULT 200,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (test_id) REFERENCES celpip_tests(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- SPEAKING PROMPTS
CREATE TABLE celpip_speaking_tasks (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    test_id INT UNSIGNED NOT NULL,
    task_number TINYINT UNSIGNED NOT NULL, -- 1..8
    task_type VARCHAR(50) NOT NULL,        -- advice, experience, describe_scene, etc.
    prompt_text TEXT NOT NULL,
    image_file VARCHAR(255),               -- for describing scenes
    prep_time_seconds TINYINT UNSIGNED DEFAULT 30,
    speak_time_seconds TINYINT UNSIGNED DEFAULT 60,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (test_id) REFERENCES celpip_tests(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- TEST ATTEMPTS (per skill)
CREATE TABLE celpip_attempts (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id INT UNSIGNED NOT NULL,
    test_id INT UNSIGNED NOT NULL,
    started_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    completed_at DATETIME NULL,
    raw_score DECIMAL(6,2) DEFAULT 0,
    max_score DECIMAL(6,2) DEFAULT 0,
    celpip_score TINYINT UNSIGNED,         -- 0-12
    clb_level TINYINT UNSIGNED,
    skill ENUM('listening','reading','writing','speaking') NOT NULL,
    status ENUM('in_progress','submitted','scored') DEFAULT 'in_progress',
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (test_id) REFERENCES celpip_tests(id)
) ENGINE=InnoDB;

-- OBJECTIVE ANSWERS (Listening + Reading)
CREATE TABLE celpip_answers (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    attempt_id INT UNSIGNED NOT NULL,
    question_id INT UNSIGNED NOT NULL,
    answer_text VARCHAR(255),
    is_correct TINYINT(1),
    score_awarded DECIMAL(4,2) DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (attempt_id) REFERENCES celpip_attempts(id) ON DELETE CASCADE,
    FOREIGN KEY (question_id) REFERENCES celpip_questions(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- WRITING RESPONSES
CREATE TABLE celpip_writing_responses (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    attempt_id INT UNSIGNED NOT NULL,
    task_id INT UNSIGNED NOT NULL,
    response_text MEDIUMTEXT NOT NULL,
    word_count SMALLINT UNSIGNED,
    teacher_id INT UNSIGNED NULL,
    celpip_score TINYINT UNSIGNED NULL,
    clb_level TINYINT UNSIGNED NULL,
    feedback TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (attempt_id) REFERENCES celpip_attempts(id) ON DELETE CASCADE,
    FOREIGN KEY (task_id) REFERENCES celpip_writing_tasks(id) ON DELETE CASCADE,
    FOREIGN KEY (teacher_id) REFERENCES users(id)
) ENGINE=InnoDB;

-- SPEAKING RESPONSES (store path to audio file)
CREATE TABLE celpip_speaking_responses (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    attempt_id INT UNSIGNED NOT NULL,
    task_id INT UNSIGNED NOT NULL,
    audio_file VARCHAR(255) NOT NULL,
    teacher_id INT UNSIGNED NULL,
    celpip_score TINYINT UNSIGNED NULL,
    clb_level TINYINT UNSIGNED NULL,
    feedback TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (attempt_id) REFERENCES celpip_attempts(id) ON DELETE CASCADE,
    FOREIGN KEY (task_id) REFERENCES celpip_speaking_tasks(id) ON DELETE CASCADE,
    FOREIGN KEY (teacher_id) REFERENCES users(id)
) ENGINE=InnoDB;
