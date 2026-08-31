# Harbor anonymous message board decision

**Request date:** August 30, 2026

**Decision state:** User choice required before network implementation
**Existing non-negotiable:** Personal journals, check-ins, questions, plans, and private settings remain local and are never community data.

## The unavoidable boundary

A real message board shared by women on different devices cannot remain entirely local. Publishing a post deliberately sends its text to other systems and people. Even with no account, a hosting provider can ordinarily observe request metadata such as IP address and time. Other members can copy or screenshot a post. Harbor must not promise “untraceable,” guaranteed deletion from other people’s devices, or emergency monitoring.

## Option A — device-local reflection wall

- Bundled composite stories plus the woman’s own private notes
- No server, posting, strangers, moderation, IP metadata, or transmission
- Fully compatible with the current privacy promise
- Not a real multi-user message board and must never be presented as one

## Option B — separate opt-in moderated board (recommended if real community is required)

The community becomes a clearly separated network feature with a second consent boundary.

### Product rules

- No account, email, phone number, contact upload, advertising, analytics, follower count, engagement streak, direct message, image upload, location, or public profile
- A fresh random display name that the woman can rotate; do not imply it guarantees anonymity
- Text-only posts and replies, topic tags, content warning, report, block/mute, and deliberate delete request
- No journal/check-in/question/plan text can be attached or auto-shared
- No visible popularity ranking; chronological and safety-reviewed discovery
- Clear pre-post warning that publishing leaves the device and other people may copy it
- Crisis prompts provide user-controlled call/text handoff; the board is not continuously monitored emergency care

### Service rules

- Separate community API and database; no access to Harbor’s local vault
- TLS in transit and encryption at rest
- No third-party scripts, SDK telemetry, ad tech, fingerprinting, session replay, or behavioral analytics
- Application logs exclude post bodies and identifiers; reverse-proxy/host metadata retention minimized and disclosed
- Short retention for operational metadata; documented deletion and legal-hold limits
- Rate limiting designed without persistent advertising identifiers; independent abuse/security review
- Named, trained human moderation with coverage, escalation, appeal, evidence handling, and moderator-wellbeing procedures
- Public moderation rules prohibit misogyny, harassment, hate, medical misinformation, exploitation, doxxing, sexualization of children, and coercive partner surveillance
- Regional legal/privacy review, child-safety reporting analysis, crisis-policy review, penetration test, and incident drill before public availability

### Honest promise

“No Harbor account and no tracking. Your private Harbor vault never leaves your device. Anything you choose to publish is sent to Harbor Community and visible to other members. We minimize server metadata, but cannot make internet posting untraceable or prevent copies.”

## Option C — peer-to-peer board

Not recommended. Peer discovery can expose network addresses, moderation and deletion are substantially harder, offline delivery is unreliable, and mobile background restrictions make it a poor safety/privacy tradeoff for this audience.

## Approval needed

The user must explicitly choose whether Harbor may transmit deliberately published board posts to a separately governed service. Until then, Option A remains the accepted local-only boundary and no simulated community activity will be added.
