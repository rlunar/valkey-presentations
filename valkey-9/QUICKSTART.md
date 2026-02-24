# Quick Start Guide

Get your Valkey 9.0 presentation running in 5 minutes!

## Step 1: Install Dependencies (2 minutes)

```bash
# Run the setup script
chmod +x setup.sh
./setup.sh
```

Or manually:
```bash
pnpm install -g @slidev/cli
pnpm install
```

## Step 2: Start the Presentation (30 seconds)

```bash
pnpm run dev
# or
slidev valkey-9-presentation.md
```

Your browser will open to `http://localhost:3030`

## Step 3: Open Presenter Mode (30 seconds)

In a new browser window/tab, go to:
```
http://localhost:3030/presenter
```

This gives you:
- Current and next slide preview
- Speaker notes
- Timer
- Slide progress

## Step 4: Prepare Demos (2 minutes)

### Terminal 1: Start Valkey
```bash
# If you have Valkey installed locally:
valkey-server

# Or with Docker:
docker run -d -p 6379:6379 valkey/valkey:9.0
```

### Terminal 2: Valkey CLI
```bash
valkey-cli
# or
docker exec -it <container-id> valkey-cli
```

### Terminal 3: Keep demo-script.md open
```bash
# Open in your editor or terminal
cat demo-script.md
```

## During the Presentation

### Navigation
- **Space** or **→** - Next slide
- **Shift+Space** or **←** - Previous slide
- **Home** - First slide
- **End** - Last slide
- **O** - Overview mode
- **D** - Dark mode
- **F** - Fullscreen

### Demo Flow

**Hash Field Expiration Demo (Slide 19):**
```redis
HSET user:1001 name "Alice" session "abc123"
HEXPIRE user:1001 60 session
HTTL user:1001 session
# Wait, then:
HGETALL user:1001  # session is gone!
```

**Numbered Databases Demo (Slide 36):**
```redis
SELECT 0
SET mykey "value0"
SELECT 5
SET mykey "value5"
SELECT 0
GET mykey  # Returns: "value0"
```

**MOVE Command Demo (Slide 37):**
```redis
SELECT 0
SET post:123 "content"
MOVE post:123 1
GET post:123  # Returns: nil
SELECT 1
GET post:123  # Returns: "content"
```

## Pro Tips

1. **Pre-stage commands**: Copy demo commands to a text file for easy paste
2. **Increase font size**: Make terminal readable from the back of the room
3. **Use presenter mode**: Keep track of time and see upcoming slides
4. **Test beforehand**: Run through all demos at least once
5. **Have backup**: Screenshots or pre-recorded video if demos fail

## Common Issues

### Slidev won't start
```bash
rm -rf node_modules package-lock.json
pnpm install
slidev valkey-9-presentation.md
```

### Valkey connection fails
```bash
# Check if running
ps aux | grep valkey-server

# Check port
netstat -tlnp | grep 6379

# Restart
pkill valkey-server
valkey-server &
```

### Presenter mode not working
- Use a different browser
- Try incognito/private mode
- Check for browser extensions blocking

## Export for Sharing

### PDF (for sending to attendees)
```bash
pnpm run export:pdf
# Creates: valkey-9-presentation.pdf
```

### PowerPoint (for editing)
```bash
pnpm run export:pptx
# Creates: valkey-9-presentation.pptx
```

### Static HTML (for hosting)
```bash
pnpm run build
# Creates: dist/ folder
```

## Customization Checklist

Before presenting, update:
- [ ] Your name and title (Slide 2)
- [ ] Your contact info (Last slide)
- [ ] Company-specific examples (if applicable)
- [ ] Demo timing based on your pace
- [ ] Additional slides for your context

## Time Allocation (35 min)

- 0:00-3:00 - Introduction & Overview
- 3:00-10:00 - Atomic Slot Migrations + Demo
- 10:00-20:00 - Hash Field Expiration + Demo
- 20:00-28:00 - Numbered Databases + Demo
- 28:00-32:00 - 1B RPS & Other Features
- 32:00-35:00 - Q&A

Adjust based on:
- Audience questions
- Demo speed
- Technical depth needed
- Available total time

## Resources During Talk

Keep these tabs open:
1. Presentation (`http://localhost:3030`)
2. Presenter mode (`http://localhost:3030/presenter`)
3. `demo-script.md`
4. Valkey CLI terminal
5. Valkey documentation (https://valkey.io/docs/)

## After the Talk

Share with attendees:
1. Link to presentation files
2. Demo scripts
3. Valkey resources:
   - https://valkey.io
   - https://github.com/valkey-io/valkey
   - https://valkey.io/community/

## Need Help?

- Check `README.md` for detailed instructions
- See `demo-script.md` for all commands
- Visit Valkey community: https://valkey.io/community/

---

**You're all set! Break a leg! 🎤🚀**
