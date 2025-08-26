# Mindload - Pricing and Products Documentation

## Overview
This document provides comprehensive information about Mindload's in-app purchase products, pricing structure, and implementation details for Apple App Store review compliance.

## Product Catalog

### 1. Pro Monthly Subscription
- **Product ID**: `mindload_pro_monthly`
- **Type**: Auto-renewable subscription
- **Subscription Group**: `mindload_pro`
- **Base Price**: $5.99 USD per month
- **Introductory Offer**: $2.99 USD for the first month
- **Renewal**: Automatically renews monthly at $5.99 USD
- **Cancellation**: Can be canceled anytime in App Store Settings

**Features Included**:
- 15 ML Tokens per month
- Unlimited AI-powered study material generation
- Priority AI processing
- Advanced study features
- Export capabilities
- Priority customer support

**Localization**: Prices automatically converted to local currency by App Store

### 2. Pro Annual Subscription
- **Product ID**: `mindload_pro_annual`
- **Type**: Auto-renewable subscription
- **Subscription Group**: `mindload_pro`
- **Base Price**: $49.99 USD per year
- **Introductory Offer**: $39.99 USD for the first year
- **Renewal**: Automatically renews annually at $49.99 USD
- **Savings**: 28% discount compared to monthly plan
- **Cancellation**: Can be canceled anytime in App Store Settings

**Features Included**:
- 30 ML Tokens per month (double monthly plan)
- Credit rollover up to 30 tokens
- All Pro Monthly features
- Annual savings discount
- Premium study analytics

**Localization**: Prices automatically converted to local currency by App Store

### 3. Starter Pack (Consumable)
- **Product ID**: `mindload_starter_pack_100`
- **Type**: Consumable (one-time purchase)
- **Price**: $1.99 USD
- **Credits**: +5 ML Tokens immediately
- **Usage**: One-time purchase, credits added to account

**Features Included**:
- 5 ML Tokens added to current balance
- No subscription commitment
- Immediate access to AI features
- Perfect for trying premium features

**Localization**: Prices automatically converted to local currency by App Store

## ML Tokens System

### What are ML Tokens?
ML Tokens (MindLoad Tokens) are the in-app currency that powers AI-powered learning features. Each token allows users to generate study materials using artificial intelligence.

### Token Usage
- **AI Generation**: 1 token per generation
- **Smart Quizzes**: 1 token per quiz creation
- **Study Tips**: 1 token per tips generation
- **Flashcard Creation**: 1 token per set of flashcards

### Token Allocation by Plan
- **Free Tier**: 3 tokens per month (server-enforced limit)
- **Pro Monthly**: 15 tokens per month
- **Pro Annual**: 30 tokens per month
- **Starter Pack**: +5 tokens (one-time)

### Token Rollover (Pro Annual Only)
- Up to 30 tokens can roll over to the next month
- Rollover credits expire after 1 month
- Helps users who don't use all tokens in a given month

## Pricing Strategy

### Value Proposition
- **Pro Monthly**: $5.99/month = $0.40 per token
- **Pro Annual**: $49.99/year = $0.28 per token (30% savings)
- **Starter Pack**: $1.99 for 5 tokens = $0.40 per token

### Competitive Analysis
- Similar AI-powered study apps: $8-15/month
- Mindload Pro Monthly: $5.99/month (competitive pricing)
- Mindload Pro Annual: $4.17/month effective (best value)

### Introductory Offers
- **Monthly Plan**: $2.99 first month (50% discount)
- **Annual Plan**: $39.99 first year (20% discount)
- **Purpose**: Allow users to experience premium features at reduced cost

## Technical Implementation

### StoreKit 2 Integration
- **Framework**: StoreKit 2 (iOS 15.0+)
- **Fallback**: StoreKit 1 for older devices
- **Receipt Validation**: On-device validation with server verification
- **Subscription Management**: Automatic renewal handling

### Product Configuration
```swift
// Subscription Group Configuration
SubscriptionGroup: mindload_pro
- mindload_pro_monthly (Monthly plan)
- mindload_pro_annual (Annual plan)

// Consumable Products
- mindload_starter_pack_100 (Starter pack)
```

### Receipt Validation
- **Primary**: On-device StoreKit 2 validation
- **Secondary**: Server-side verification via Firebase
- **Security**: JWT-based Apple verification
- **Fallback**: Local receipt storage and validation

## Compliance & Guidelines

### Apple App Store Guidelines
- **3.1.1**: All digital content purchases use Apple's IAP system
- **3.1.2**: Subscription terms clearly displayed
- **3.1.3**: Restore purchases functionality implemented
- **3.1.4**: Subscription management accessible
- **3.1.5**: No external payment links for digital content

### Privacy & Data
- **User Data**: Minimal collection, encrypted storage
- **Purchase History**: Stored locally and in user's Apple account
- **Analytics**: Anonymous usage data for service improvement
- **GDPR**: Full compliance with data protection regulations

### Accessibility
- **Dynamic Type**: Support up to 120% text scaling
- **VoiceOver**: Full navigation support
- **High Contrast**: Support for accessibility features
- **WCAG 2.1 AA**: Compliance with accessibility standards

## User Experience

### Purchase Flow
1. **Discovery**: Clear feature comparison in paywall
2. **Selection**: Easy plan selection with clear pricing
3. **Purchase**: Secure Apple Pay integration
4. **Confirmation**: Immediate access to purchased features
5. **Management**: Easy subscription management in App Store

### Restore Purchases
- **Visibility**: Prominent "Restore" button in paywall
- **Process**: Simple one-tap restoration
- **Feedback**: Clear success/error messages
- **Recovery**: Automatic entitlement restoration

### Subscription Management
- **Status**: Clear current subscription status display
- **Renewal**: Automatic renewal with user control
- **Cancellation**: Easy cancellation through App Store
- **Upgrades/Downgrades**: Seamless plan changes

## Testing & Validation

### Test Environment
- **StoreKit Configuration**: Local testing with Configuration.storekit
- **TestFlight**: Internal and external testing
- **Sandbox**: Apple's sandbox environment for testing
- **Real Devices**: Physical device testing for edge cases

### Test Scenarios
- **New User Purchase**: Complete purchase flow for new users
- **Existing User Restore**: Restore previous purchases
- **Subscription Renewal**: Test automatic renewal
- **Error Handling**: Network failures, authentication errors
- **Accessibility**: VoiceOver, Dynamic Type testing

### Quality Assurance
- **Unit Tests**: Service layer testing
- **Integration Tests**: End-to-end purchase flow
- **User Acceptance**: TestFlight user feedback
- **Performance**: Purchase completion time < 10 seconds

## Support & Customer Service

### Purchase Support
- **In-App Help**: Built-in help and FAQ
- **Email Support**: Direct support for purchase issues
- **Apple Support**: Integration with Apple's support system
- **Documentation**: Clear user guides and tutorials

### Refund Policy
- **Apple's Policy**: Follows Apple's standard refund policy
- **Subscription Cancellation**: Immediate cancellation through App Store
- **Pro-rated Refunds**: Apple handles subscription refunds
- **Dispute Resolution**: Apple's dispute resolution process

### Customer Education
- **Feature Guides**: How to use purchased features
- **Token Management**: Understanding ML Token system
- **Subscription Benefits**: Clear value proposition
- **Troubleshooting**: Common issues and solutions

## Business Metrics

### Key Performance Indicators
- **Conversion Rate**: Free to paid user conversion
- **Retention Rate**: Subscription renewal rates
- **Average Revenue Per User (ARPU)**: Monthly recurring revenue
- **Customer Lifetime Value (CLV)**: Long-term user value

### Revenue Projections
- **Month 1**: 5-10% conversion rate
- **Month 6**: 15-25% conversion rate
- **Month 12**: 20-35% conversion rate
- **Annual Growth**: 40-60% year-over-year growth

### Market Analysis
- **Target Market**: Students, professionals, lifelong learners
- **Market Size**: $2.5B global e-learning market
- **Competitive Advantage**: AI-powered personalization
- **Growth Strategy**: Freemium model with premium features

## Legal & Compliance

### Terms of Service
- **Subscription Terms**: Clear renewal and cancellation terms
- **Usage Rights**: Fair use policy for AI-generated content
- **Intellectual Property**: User-generated content ownership
- **Liability**: Standard limitation of liability

### Privacy Policy
- **Data Collection**: Minimal data collection for service provision
- **Data Usage**: Service improvement and personalization
- **Data Sharing**: No third-party data sharing
- **User Rights**: Full GDPR compliance and user control

### Regulatory Compliance
- **GDPR**: European data protection compliance
- **CCPA**: California privacy law compliance
- **COPPA**: Children's privacy protection
- **International**: Compliance with local regulations

## Review Notes for Apple

### App Store Review Compliance
- **Guideline 3.1.1**: ✅ All digital content uses Apple's IAP system
- **Guideline 3.1.2**: ✅ Subscription terms clearly displayed
- **Guideline 3.1.3**: ✅ Restore purchases functionality implemented
- **Guideline 3.1.4**: ✅ Subscription management accessible
- **Guideline 3.1.5**: ✅ No external payment links

### Technical Implementation
- **StoreKit 2**: ✅ Latest framework implementation
- **Receipt Validation**: ✅ On-device and server verification
- **Error Handling**: ✅ Comprehensive error handling
- **Accessibility**: ✅ Full accessibility support

### User Experience
- **Clear Pricing**: ✅ Transparent pricing structure
- **Feature Comparison**: ✅ Clear value proposition
- **Purchase Flow**: ✅ Simple and secure
- **Support**: ✅ Comprehensive customer support

### Content & Features
- **Educational Value**: ✅ AI-powered learning tools
- **Content Quality**: ✅ High-quality study materials
- **User Safety**: ✅ Safe and appropriate content
- **Age Rating**: ✅ Appropriate for all ages

## Future Enhancements

### Planned Features
- **Family Sharing**: Subscription sharing for families
- **Enterprise Plans**: Business and educational institution plans
- **Advanced Analytics**: Detailed learning progress tracking
- **Collaborative Features**: Study group functionality

### Pricing Evolution
- **Market Research**: Regular competitive analysis
- **User Feedback**: Pricing optimization based on feedback
- **Value Addition**: New features to justify pricing
- **Regional Pricing**: Localized pricing strategies

### Technology Updates
- **AI Improvements**: Enhanced AI capabilities
- **Performance**: Faster generation and processing
- **Integration**: Better third-party tool integration
- **Platform Expansion**: Web and Android versions

---

**Document Version**: 1.0  
**Last Updated**: [Current Date]  
**Next Review**: [Date + 1 month]  
**Contact**: [Development Team Contact Information]
