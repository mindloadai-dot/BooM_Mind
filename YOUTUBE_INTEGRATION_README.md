# YouTube Integration for Mindload

## Overview
This document outlines the complete YouTube integration implementation for the Mindload Flutter application, allowing users to create study materials from YouTube video transcripts.

## Features
- **YouTube Link Detection**: Automatically detects YouTube URLs in text input
- **Video Preview**: Shows thumbnail, title, channel, duration, and transcript availability
- **Token Estimation**: Calculates MindLoad Token costs before processing
- **Long-Press Confirmation**: Requires 600ms long-press to confirm ingest
- **Plan-Based Limits**: Enforces subscription-based duration and monthly video restrictions
- **Seamless Integration**: Works alongside existing text and PDF upload functionality
- **Comprehensive Benefits Display**: YouTube integration information is consistently shown across all plan and benefits screens

## Integration Points

### 1. Create Screen (`lib/screens/create_screen.dart`)
- **Primary Entry Point**: Main "Create Study Set" screen
- **YouTube Support**: Enhanced content input with YouTube link detection
- **Auto-Preview**: Shows video preview when YouTube link is detected
- **Auto-Title**: Fills study set title from video title
- **Direct Ingest**: Processes YouTube videos directly to study materials

### 2. Home Screen (`lib/screens/home_screen.dart`)
- **Paste Text Dialog**: Enhanced dialog supporting both text and YouTube links
- **Quick Access**: Accessible via "PASTE TEXT" button in document upload options
- **Real-time Preview**: Shows YouTube preview as user types
- **Smart Processing**: Automatically routes to appropriate processing method

### 3. Enhanced Upload Panel (`lib/widgets/enhanced_upload_panel.dart`)
- **Reusable Component**: Used across multiple screens
- **YouTube Detection**: Automatically switches between text and YouTube modes
- **Token Estimation**: Preflight cost calculation for both input types
- **Depth Selection**: Analysis depth options for different study needs

### 4. Enhanced Text Upload Screen (`lib/screens/enhanced_text_upload_screen.dart`)
- **Standalone Screen**: Dedicated text/YouTube input screen

## Plan-Based YouTube Access

YouTube integration is available across different subscription tiers with varying limits:

### Dendrite (Free)
- **YouTube Access**: ❌ Not available
- **Duration Limit**: N/A
- **Monthly Videos**: 0
- **Upgrade Required**: Yes

### Axon
- **YouTube Access**: ✅ Available
- **Duration Limit**: 45 minute videos
- **Monthly Videos**: 1 video/month
- **Features**: Basic video processing

### Neuron
- **YouTube Access**: ✅ Available
- **Duration Limit**: 45 minute videos
- **Monthly Videos**: 3 videos/month
- **Features**: Enhanced processing with GPT-4 Turbo

### Cortex
- **YouTube Access**: ✅ Available
- **Duration Limit**: 45 minute videos
- **Monthly Videos**: 5 videos/month
- **Features**: Extended content processing

### Singularity
- **YouTube Access**: ✅ Available
- **Duration Limit**: 45 minute videos
- **Monthly Videos**: 10 videos/month
- **Features**: Maximum content processing capability

### Legacy Plans (Pro/Annual Pro)
- **Pro**: 45 minute videos, 2 videos/month
- **Annual Pro**: 1.5 hour videos, 3 videos/month
- **Full Integration**: Complete YouTube workflow implementation
- **Error Handling**: Comprehensive error states and user feedback

## User Flow

### Text Input Flow
1. User pastes text content
2. Content is processed normally
3. Study materials are generated

### YouTube Link Flow
1. User pastes YouTube URL
2. System detects YouTube link (500ms debounce)
3. Video preview is fetched and displayed
4. User sees thumbnail, title, channel, duration, transcript status
5. Token cost is estimated and displayed
6. User long-presses (600ms) to confirm ingest
7. Transcript is fetched server-side and sanitized
8. Study materials are created from transcript
9. User is redirected to study screen

## Technical Implementation

### Frontend Components
- **`YouTubeUtils`**: Core utility functions for URL parsing and validation
- **`YouTubePreviewCard`**: UI component for video preview display
- **`YouTubeService`**: Service layer for API communication
- **`YouTubePreview`**: Data models for preview and ingest operations

### Backend Services
- **`youtubePreview`**: Cloud Function for video metadata and transcript availability
- **`youtubeIngest`**: Cloud Function for transcript processing and material creation
- **LRU Cache**: Backend caching for preview results (15 min TTL)
- **Idempotency**: Prevents duplicate processing of same video

### State Management
- **Provider Pattern**: Consistent with existing app architecture
- **Debounced Input**: 500ms delay to prevent excessive API calls
- **Loading States**: Clear feedback during preview and ingest operations
- **Error Handling**: User-friendly error messages and recovery options

## Configuration

### Environment Variables
```typescript
YOUTUBE_API_KEY=your_youtube_api_key
TOKENS_PER_ML_TOKEN=750
FREE_MAX_DURATION_SECONDS=2700
PRO_MAX_DURATION_SECONDS=2700
TRANSCRIPT_LANG_FALLBACKS=en,en-US
```

### Plan Limits
- **Free Tier**: 45 minutes max, 1 YouTube ingest per month
- **Pro Tier**: 45 minutes max, unlimited YouTube ingests
- **Token Costs**: Fixed 5 MindLoad tokens per YouTube video

## Security Features
- **App Check**: Firebase App Check on all endpoints
- **Authentication**: User authentication required for all operations
- **Rate Limiting**: Prevents abuse through plan-based restrictions
- **Input Validation**: Comprehensive URL and video ID validation

## Performance Optimizations
- **Frontend Caching**: In-memory cache with 15-minute TTL
- **Backend Caching**: LRU cache for preview results
- **Debounced Input**: Prevents excessive API calls
- **Lazy Loading**: Preview only fetched when needed
- **Idempotent Operations**: Prevents duplicate work

## Error Handling
- **Network Errors**: Retry logic with exponential backoff
- **Video Unavailable**: Clear messaging for private/removed videos
- **Transcript Issues**: Fallback options when captions unavailable
- **Plan Limits**: Clear upgrade prompts when limits exceeded

## Testing
- **Unit Tests**: Frontend utilities and models
- **Widget Tests**: UI components and interactions
- **Integration Tests**: End-to-end YouTube workflow
- **Cloud Function Tests**: Backend logic and error handling

## Deployment
- **Frontend**: No additional deployment steps required
- **Backend**: Deploy Cloud Functions with YouTube configuration
- **Environment**: Set required environment variables
- **Monitoring**: Enable Firebase App Check and monitoring

## Future Enhancements
- **Multiple Languages**: Support for non-English transcripts
- **Video Playlists**: Process entire YouTube playlists
- **Live Streams**: Support for live content with available captions
- **Advanced Analytics**: Usage tracking and optimization insights
- **Batch Processing**: Multiple video processing in single operation

## Troubleshooting

### Common Issues
1. **Preview Not Loading**: Check YouTube API key and network connectivity
2. **Transcript Unavailable**: Verify video has captions enabled
3. **Token Calculation Errors**: Check plan limits and available credits
4. **Long-Press Not Working**: Ensure 600ms threshold is met

### Debug Information
- Check Firebase Functions logs for backend errors
- Verify App Check token generation
- Monitor token balance and plan status
- Check video accessibility and caption availability

## Support
For technical support or feature requests related to YouTube integration, please refer to the development team or create an issue in the project repository.
