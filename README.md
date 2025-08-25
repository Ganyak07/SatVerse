# SatVerse

> A Bitcoin-native digital identity & social layer powered by Stacks smart contracts.

## Overview

SatVerse creates a decentralized social identity layer built on Bitcoin through Stacks smart contracts. Users can create profiles, connect with others, and share content while maintaining full ownership of their digital identity anchored to Bitcoin's security.

## Features (Phase 1)

### Identity Management
- **Username Registration**: Unique usernames (3-20 characters)
- **Profile Creation**: Bio and basic profile info
- **Bitcoin-Anchored**: All identities secured by Bitcoin

### Social Layer
- **Follow System**: Connect with other users
- **Post Creation**: Share thoughts (280 characters)
- **Like System**: Engage with content
- **Social Graph**: Track follower/following counts

## Project Structure

```
satverse/
├── contracts/
│   ├── identity.clar          # User identity management
│   └── social.clar            # Social interactions
├── tests/
│   ├── identity_test.ts       # Identity contract tests
│   └── social_test.ts         # Social contract tests
├── scripts/
│   └── deploy.ts              # Deployment script
└── README.md
```

## Installation & Setup

### Prerequisites
- [Node.js](https://nodejs.org/) (v16 or higher)
- [Clarinet](https://github.com/hirosystems/clarinet) CLI tool
- [Stacks CLI](https://docs.stacks.co/build-apps/references/stacks-cli)

### Quick Start

```bash
# Clone the repository
git clone https://github.com/your-org/satverse.git
cd satverse

# Install Clarinet
npm install -g @hirosystems/clarinet

# Initialize Clarinet project
clarinet new satverse
cd satverse

# Copy contracts to contracts folder
# identity.clar and social.clar

# Run tests
clarinet test

# Deploy to testnet
clarinet deploy --testnet
```

## Smart Contract API

### Identity Contract

#### Register User
```clarity
(contract-call? .identity register-user "username" "Your bio here")
```

#### Update Bio
```clarity
(contract-call? .identity update-bio "New bio content")
```

#### Get User Profile
```clarity
(contract-call? .identity get-user 'SP1ABC123...)
```

### Social Contract

#### Follow User
```clarity
(contract-call? .social follow-user 'SP1ABC123...)
```

#### Create Post
```clarity
(contract-call? .social create-post "Hello SatVerse! 🚀")
```

#### Like Post
```clarity
(contract-call? .social like-post u1)
```

#### Check Following Status
```clarity
(contract-call? .social is-following 'SP1ABC123... 'SP2DEF456...)
```

## Testing

```bash
# Run all tests
clarinet test

# Run specific test file
clarinet test tests/identity_test.ts

# Check contract syntax
clarinet check
```

## Deployment

### Testnet Deployment
```bash
# Deploy to Stacks testnet
clarinet deploy --testnet

# Verify deployment
stx call-contract-func -t testnet SP1ABC123.identity get-user
```

### Mainnet Deployment
```bash
# Deploy to Stacks mainnet
clarinet deploy --mainnet
```

## Data Models

### User Profile
```clarity
{
  username: (string-ascii 50),
  bio: (string-utf8 200),
  created-at: uint,
  is-verified: bool
}
```

### Social Connection
```clarity
{
  follower: principal,
  following: principal,
  created-at: uint
}
```

### Post
```clarity
{
  author: principal,
  content: (string-utf8 280),
  created-at: uint,
  likes: uint
}
```

## Security Considerations

- All usernames are unique and immutable after registration
- Users can only modify their own profiles
- Social connections are bilateral (both parties control their side)
- Post likes are one-per-user to prevent spam
- All operations are Bitcoin-timestamped for immutability

## Roadmap

### Phase 1 (Current) ✅
- [x] Basic identity management
- [x] Simple social connections
- [x] Post creation and likes
- [x] Core smart contracts

### Phase 2 (Next)
- [ ] Enhanced social features
- [ ] Reputation system
- [ ] Community creation
- [ ] Content moderation

### Phase 3 (Future)
- [ ] Cross-platform verification
- [ ] NFT profile integration
- [ ] Decentralized messaging
- [ ] Advanced analytics

## Contributing

We welcome contributions to SatVerse! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

### Development Workflow
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests: `clarinet test`
5. Submit a pull request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.



## Quick Examples

### Register and Create Your First Post
```bash
# 1. Register user
stx call-contract-func -t testnet SP1ABC.identity register-user "alice" "Bitcoin maximalist"

# 2. Create first post
stx call-contract-func -t testnet SP1ABC.social create-post "GM SatVerse! 🌅"

# 3. Follow someone
stx call-contract-func -t testnet SP1ABC.social follow-user 'SP2DEF456...
```

## Known Issues

- Username changes not supported in Phase 1
- Post deletion not implemented yet
- Limited to 280 characters per post
