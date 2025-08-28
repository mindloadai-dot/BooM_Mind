# YouTube Subtitle Feature Enhancement

## Overview
The YouTube subtitle/transcript feature has been enhanced to capture subtitle information and generate questions directly from the video content.

## Key Improvements

### 1. **YouTube Transcript Processor Service**
- New `YouTubeTranscriptProcessor` service that handles the complete workflow
- Extracts subtitles/captions from YouTube videos
- Processes transcript text to generate focused study materials
- Creates questions that directly reference video content

### 2. **Subtitle-Based Question Generation**
Questions now:
- Use direct quotes from the video subtitles
- Test comprehension of specific points made in the video
- Include questions about the sequence of topics discussed
- Reference examples and explanations given in the video

Example questions generated:
- "According to the video, what is..."
- "The speaker mentioned that..."
- "In the video, which example was used to explain..."
- "What topic was discussed after..."

### 3. **Enhanced StudySet Model**
- Added `sourceUrl` field to track the YouTube video source
- Added `type` field to distinguish YouTube-sourced materials
- Added `metadata` field to store video details (ID, channel, duration, language)
- Added timestamp fields for better tracking

### 4. **Intelligent Processing**
- Checks if subtitles are available before processing
- Supports multiple languages with preferred language selection
- Segments transcript into meaningful chunks for better question generation
- Falls back to basic question generation if AI services fail

## Usage Flow

1. **User enters YouTube URL** in the home screen
2. **System checks subtitle availability** and shows preview
3. **User confirms processing** 
4. **System:**
   - Ingests the transcript from YouTube
   - Retrieves subtitle content from Cloud Storage
   - Processes transcript into segments
   - Generates flashcards and quiz questions from subtitles
   - Creates a complete study set
   - Saves to Firestore for future access

5. **User is navigated** to the study screen with generated materials

## Technical Details

### Files Modified:
- `lib/services/youtube_transcript_processor.dart` - New service for processing
- `lib/screens/home_screen.dart` - Updated to use new processor
- `lib/models/study_data.dart` - Enhanced StudySet model

### Key Methods:
```dart
// Process YouTube video with subtitle extraction
final studySet = await processor.processYouTubeVideo(
  videoId: preview.videoId,
  userId: userId,
  preferredLanguage: preview.primaryLang,
  flashcardCount: 20,
  quizCount: 15,
  useSubtitlesForQuestions: true,
);
```

### Features:
- **Duplicate Detection**: Checks if video has already been processed
- **Error Handling**: Graceful fallback for AI service failures
- **Progress Tracking**: Shows number of flashcards and questions created
- **Metadata Storage**: Preserves video information for reference

## Benefits

1. **More Relevant Questions**: Questions directly relate to video content
2. **Better Learning**: Tests actual comprehension of presented material
3. **Context Preservation**: Questions reference specific video segments
4. **Language Support**: Works with videos in multiple languages
5. **Efficient Processing**: Avoids reprocessing already-ingested videos

## Future Enhancements

- Add timestamp information to link questions back to video segments
- Support for extracting key visual information from videos
- Integration with video playback for review
- Support for playlists and series processing
