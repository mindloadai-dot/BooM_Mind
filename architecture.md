# Mindload - AI Study App Architecture

## Project Overview
Mindload is a minimalist sci-fi AI study app that transforms PDFs and text into interactive flashcards and quizzes using OpenAI API. Features include Face ID authentication, Ultra Study Mode with focus timer and binaural beats, push notifications, and comprehensive progress tracking.

## Core Features (MVP)
1. **Authentication**: Face ID/biometric authentication
2. **Home Screen**: Recent study sets display
3. **Content Upload**: PDF upload and text paste functionality
4. **AI Generation**: OpenAI-powered flashcards and quizzes (MCQ, T/F, short answer)
5. **Ultra Study Mode**: Custom focus timer with binaural beats player
6. **Profile System**: Streaks, quiz results, XP tracking
7. **Notifications**: Daily reminders and surprise pop quizzes

## Technical Architecture

### File Structure (10 files total)
1. `lib/main.dart` - App entry point
2. `lib/theme.dart` - Dark terminal-inspired theme
3. `lib/models/study_data.dart` - Data models
4. `lib/services/storage_service.dart` - Local storage management
5. `lib/services/openai_service.dart` - OpenAI API integration
6. `lib/screens/auth_screen.dart` - Face ID authentication
7. `lib/screens/home_screen.dart` - Main dashboard
8. `lib/screens/study_screen.dart` - Quiz/flashcard interface
9. `lib/screens/ultra_mode_screen.dart` - Focus timer with binaural beats
10. `lib/screens/profile_screen.dart` - User stats and settings

### Data Models
- **StudySet**: ID, title, content, flashcards, quizzes, created_date
- **Flashcard**: question, answer, difficulty, last_reviewed
- **Quiz**: questions, answers, type (MCQ/TF/SA), results
- **UserProgress**: streaks, xp, quiz_results, study_time

### Core Dependencies
- `local_auth`: Face ID authentication
- `shared_preferences`: Local data storage
- `http`: OpenAI API calls
- `file_picker`: PDF upload
- `flutter_local_notifications`: Push notifications
- `audioplayers`: Binaural beats playback

### UI/UX Design
- **Theme**: Dark terminal-inspired with cyan/green accents
- **Typography**: Monospace font (JetBrains Mono)
- **Colors**: Matrix-style green terminals, cyber blue highlights
- **Animations**: Subtle glitch effects, typing animations
- **Layout**: Clean cards with rounded corners, minimal shadows

### Implementation Steps
1. Update theme with sci-fi terminal aesthetic
2. Set up data models and storage service
3. Implement Face ID authentication screen
4. Create home screen with recent study sets
5. Build content upload functionality
6. Integrate OpenAI API for content generation
7. Develop study interface (flashcards/quizzes)
8. Implement Ultra Study Mode with timer
9. Add binaural beats player functionality
10. Create profile screen with progress tracking
11. Set up push notifications system
12. Add realistic sample data
13. Test and debug complete application

### Technical Constraints
- Maximum 12 files for maintainability
- Local storage only (no external database)
- OpenAI API for AI features
- Material Design 3 principles
- Dark theme prioritized for sci-fi aesthetic