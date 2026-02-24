# Valkey 9.0 Demo Script

This document contains all the demo commands and scripts for the Valkey 9.0 presentation.

## Prerequisites

```bash
# Install Valkey 9.0
wget https://github.com/valkey-io/valkey/archive/refs/tags/9.0.0.tar.gz
tar xzf 9.0.0.tar.gz
cd valkey-9.0.0
make

# Or use Docker
docker pull valkey/valkey:9.0
```

## Demo 1: Hash Field Expiration

### Setup
```bash
# Start Valkey server
./src/valkey-server &

# Connect with CLI
./src/valkey-cli
```

### Commands
```redis
# Create a user profile with mixed data
HSET user:1001 name "Alice" age "30" email "alice@example.com" session "abc123" temp_flag "true"

# View the hash
HGETALL user:1001

# Set 10 second TTL on session and temp_flag
HEXPIRE user:1001 10 session temp_flag

# Check the TTL
HTTL user:1001 session
HTTL user:1001 temp_flag

# Get absolute expiration time
HEXPIRETIME user:1001 session

# Wait 10 seconds and check again
# (Open another terminal to show time passing)
sleep 10

# Session and temp_flag are now gone
HGETALL user:1001

# Only name, age, and email remain!
```

### Advanced Example: Feature Flags
```redis
# Create feature flags for a user
HSET features:user:42 beta-ai-chat "enabled" experiment-widget "enabled" premium-features "enabled"

# Set different TTLs
HEXPIRE features:user:42 300 beta-ai-chat          # 5 minutes
HEXPIRE features:user:42 3600 experiment-widget    # 1 hour  
HEXPIRE features:user:42 2592000 premium-features  # 30 days

# Check remaining time
HTTL features:user:42 beta-ai-chat experiment-widget premium-features

# Use HSETEX for new fields with TTL
HSETEX features:user:42 new-experiment "enabled" EX 600

# Refresh TTL when accessing
HGETEX features:user:42 beta-ai-chat EX 300
```

### Python Demo
```python
from glide import GlideClient, GlideClientConfiguration, NodeAddress, ExpirySet, ExpiryType

# Connect
addresses = [NodeAddress("localhost", 6379)]
config = GlideClientConfiguration(addresses)
client = GlideClient.create(config)

# Create user session
client.hset("session:user123", {
    "user_id": "123",
    "username": "alice",
    "role": "admin",
    "access_token": "token-abc-123",
    "session_cookie": "cookie-xyz-789"
})

# Set different TTLs
client.hexpire("session:user123", 30, ["access_token"])  # 30 seconds
client.hexpire("session:user123", 300, ["session_cookie"])  # 5 minutes

# Check TTLs
print("Access token TTL:", client.httl("session:user123", ["access_token"]))
print("Session cookie TTL:", client.httl("session:user123", ["session_cookie"]))

# Wait and verify expiration
import time
time.sleep(31)

# Access token should be gone
result = client.hgetall("session:user123")
print("After 31 seconds:", result)
# Should only have user_id, username, role, and session_cookie
```

## Demo 2: Numbered Databases in Cluster

### Setup Cluster
```bash
# Create cluster directory
cd utils/create-cluster
./create-cluster start
./create-cluster create

# Or manually:
mkdir cluster-test
cd cluster-test

# Create 6 config files (3 primaries, 3 replicas)
# node-7000.conf through node-7005.conf
# Each with:
# port <port>
# cluster-enabled yes
# cluster-config-file nodes-<port>.conf
# cluster-node-timeout 5000
# appendonly yes

# Start nodes
for port in {7000..7005}; do
    ../../src/valkey-server node-${port}.conf &
done

# Create cluster
../../src/valkey-cli --cluster create \
    127.0.0.1:7000 127.0.0.1:7001 127.0.0.1:7002 \
    127.0.0.1:7003 127.0.0.1:7004 127.0.0.1:7005 \
    --cluster-replicas 1
```

### Commands
```redis
# Connect to cluster
valkey-cli -c -p 7000

# Work in database 0
SELECT 0
SET user:1001 "Alice in DB 0"
HSET session:1001 token "abc123" created "2025-01-01"
SADD tags:1001 "premium" "verified"

# Check slot assignment
CLUSTER KEYSLOT user:1001

# Switch to database 5
SELECT 5
SET user:1001 "Bob in DB 5"
HSET session:1001 token "xyz789" created "2025-01-15"
SADD tags:1001 "trial" "new"

# Verify slot is the same
CLUSTER KEYSLOT user:1001

# Verify data separation
SELECT 0
GET user:1001  # Returns: "Alice in DB 0"

SELECT 5
GET user:1001  # Returns: "Bob in DB 5"

# Both in same slot, different databases!
```

### MOVE Command Demo
```redis
# Content moderation scenario
SELECT 0
HSET post:12345 author "user123" content "Check out this post!" status "live" upvotes "42"

# Flag content for review - move to DB 1
MOVE post:12345 1

# Content now invisible in main DB
SELECT 0
GET post:12345  # Returns: nil
HGETALL post:12345  # Returns: empty

# But available in review DB
SELECT 1
HGETALL post:12345  # Returns: all fields

# After review, move back or delete
# If approved:
MOVE post:12345 0

# If rejected:
SELECT 1
DEL post:12345
```

### Complex Key Atomic Replacement
```redis
# Build leaderboard in DB 1
SELECT 1
ZADD leaderboard:new 1000 "player1" 950 "player2" 900 "player3"
# ... add millions of scores

# Atomic swap when ready
SELECT 0
MULTI
DEL leaderboard
RENAME leaderboard:temp leaderboard
EXEC

# Wait, better approach with MOVE:
SELECT 1
# Build new leaderboard with same key name
ZADD leaderboard 1000 "player1" 950 "player2"

# Atomic swap
SELECT 0
MULTI
DEL leaderboard
MOVE leaderboard 0  # This is wrong - can't MOVE from current DB
EXEC

# Correct approach:
SELECT 1
# Build with temp name
ZADD leaderboard_new 1000 "player1" 950 "player2"

SELECT 0
MULTI
DEL leaderboard
SELECT 1
RENAME leaderboard_new leaderboard
MOVE leaderboard 0
EXEC
```

### Multi-Tenant Demo
```python
from glide import GlideClient, GlideClientConfiguration, NodeAddress

addresses = [NodeAddress("localhost", 7000)]
config = GlideClientConfiguration(addresses, request_timeout=5000)
client = GlideClient.create(config)

# Customer A - Database 0
client.select(0)
client.hset("config:app", {"theme": "dark", "language": "en", "timezone": "UTC"})
client.set("customer:name", "Acme Corp")

# Customer B - Database 1
client.select(1)
client.hset("config:app", {"theme": "light", "language": "es", "timezone": "EST"})
client.set("customer:name", "Global Industries")

# Customer C - Database 2
client.select(2)
client.hset("config:app", {"theme": "auto", "language": "fr", "timezone": "CET"})
client.set("customer:name", "Euro Solutions")

# Verify separation
for db in range(3):
    client.select(db)
    name = client.get("customer:name")
    config = client.hgetall("config:app")
    print(f"Database {db}: {name}")
    print(f"  Config: {config}")
```

## Demo 3: Atomic Slot Migration

### Setup
```bash
# You need a running cluster (use setup from Demo 2)
valkey-cli -c -p 7000
```

### Commands
```redis
# Check cluster state
CLUSTER NODES

# Identify nodes
# Let's say we have:
# Node A: abc123... (with slots 0-5460)
# Node B: def456... (with slots 5461-10922)

# Create test data in a specific slot
# First, find keys that hash to same slot
CLUSTER KEYSLOT mykey{tag}
CLUSTER KEYSLOT another{tag}
# Both should have same slot due to {tag}

# Set multiple keys in the slot
SET mykey{tag} "value1"
SET another{tag} "value2"
HSET hash{tag} field1 "data1" field2 "data2"
SADD set{tag} "member1" "member2" "member3"

# Check which node owns this slot
CLUSTER KEYSLOT mykey{tag}
# Returns slot number, e.g., 5798

# Initiate migration (from admin connection)
# In production, this happens automatically during rebalancing
# CLUSTER SETSLOT <slot> MIGRATING <target-node-id>
# CLUSTER SETSLOT <slot> IMPORTING <source-node-id>

# The migration is atomic - all keys in slot move together
# No partial state visible to clients

# Monitor migration status
CLUSTER SLOTS
```

### Monitoring Migration
```bash
# In one terminal, continuously read data
while true; do
  valkey-cli -c -p 7000 GET mykey{tag}
  sleep 0.1
done

# In another terminal, trigger rebalancing
valkey-cli --cluster rebalance 127.0.0.1:7000 --cluster-use-empty-masters

# Observe: No errors during migration!
# Atomic slot migration ensures no MOVED errors during the process
```

## Demo 4: Performance Testing

### Simple Benchmark
```bash
# Benchmark SET operations
./src/valkey-benchmark -t set -n 1000000 -d 512 -c 50

# Benchmark with hash field expiration
./src/valkey-benchmark -t hset -n 1000000 -c 50

# Custom HSETEX benchmark
cat > hsetex_benchmark.sh << 'EOF'
#!/bin/bash
for i in {1..100000}; do
  echo "HSETEX testkey$i field$i value$i EX 60"
done | valkey-cli --pipe
EOF

chmod +x hsetex_benchmark.sh
time ./hsetex_benchmark.sh
```

### Memory Usage Monitoring
```redis
# Monitor memory
INFO memory

# Create hash with many fields
for i in {1..10000}; do
  HSET largehash field$i "value$i"
done

# Check memory
INFO memory

# Add expiration to fields
HEXPIRE largehash 3600 field1 field2 field3 field4 field5

# Check memory again - should see overhead
INFO memory

# Calculate overhead per field
# (new_memory - old_memory) / number_of_expired_fields
```

### Cluster Performance
```bash
# Benchmark cluster
valkey-benchmark -t set,get -n 1000000 -c 100 -d 512 \
  --cluster \
  -h 127.0.0.1 -p 7000

# Test with different databases
valkey-benchmark -t set,get -n 1000000 -c 100 -d 512 \
  -h 127.0.0.1 -p 7000 \
  -e "SELECT 0"

valkey-benchmark -t set,get -n 1000000 -c 100 -d 512 \
  -h 127.0.0.1 -p 7000 \
  -e "SELECT 5"
```

## Demo 5: Real-World Application

### Session Management with Field Expiration
```python
import time
from glide import GlideClient, GlideClientConfiguration, NodeAddress, ExpirySet, ExpiryType

class SessionManager:
    def __init__(self, client):
        self.client = client
    
    def create_session(self, user_id, username, role):
        """Create a new user session"""
        session_key = f"session:{user_id}"
        
        # Store session data
        self.client.hset(session_key, {
            "user_id": str(user_id),
            "username": username,
            "role": role,
            "created_at": str(int(time.time()))
        })
        
        # Generate tokens
        access_token = f"access_{user_id}_{int(time.time())}"
        refresh_token = f"refresh_{user_id}_{int(time.time())}"
        
        # Store tokens with different TTLs
        self.client.hsetex(
            session_key,
            {"access_token": access_token},
            expiry=ExpirySet(ExpiryType.SEC, 900)  # 15 minutes
        )
        
        self.client.hsetex(
            session_key,
            {"refresh_token": refresh_token},
            expiry=ExpirySet(ExpiryType.SEC, 2592000)  # 30 days
        )
        
        return {
            "access_token": access_token,
            "refresh_token": refresh_token
        }
    
    def get_session(self, user_id):
        """Get session data"""
        session_key = f"session:{user_id}"
        return self.client.hgetall(session_key)
    
    def refresh_access_token(self, user_id):
        """Refresh access token using refresh token"""
        session_key = f"session:{user_id}"
        
        # Check if refresh token exists
        refresh_ttl = self.client.httl(session_key, ["refresh_token"])
        if not refresh_ttl or refresh_ttl[0] <= 0:
            return None
        
        # Generate new access token
        new_access_token = f"access_{user_id}_{int(time.time())}"
        
        # Update with new TTL
        self.client.hsetex(
            session_key,
            {"access_token": new_access_token},
            expiry=ExpirySet(ExpiryType.SEC, 900)
        )
        
        return new_access_token
    
    def logout(self, user_id):
        """Logout user by deleting session"""
        session_key = f"session:{user_id}"
        self.client.delete([session_key])

# Usage
addresses = [NodeAddress("localhost", 6379)]
config = GlideClientConfiguration(addresses)
client = GlideClient.create(config)

manager = SessionManager(client)

# Create session
tokens = manager.create_session(12345, "alice", "admin")
print("Tokens:", tokens)

# Get session
session = manager.get_session(12345)
print("Session:", session)

# Wait for access token to expire
time.sleep(901)

# Try to get session - access token should be gone
session = manager.get_session(12345)
print("After expiry:", session)
print("Notice: access_token is gone, but refresh_token remains")

# Refresh access token
new_token = manager.refresh_access_token(12345)
print("New access token:", new_token)
```

## Cleanup

```bash
# Stop cluster
cd utils/create-cluster
./create-cluster stop
./create-cluster clean

# Or manually:
pkill valkey-server
rm -rf cluster-test/
```

## Troubleshooting

### Issue: Cluster creation fails
```bash
# Make sure no valkey processes are running
pkill valkey-server

# Remove old cluster data
rm -rf nodes*.conf dump*.rdb appendonly*.aof

# Try again
```

### Issue: Connection refused
```bash
# Check if Valkey is running
ps aux | grep valkey-server

# Check port
netstat -tlnp | grep 6379

# Start if not running
./src/valkey-server &
```

### Issue: Hash field expiration not working
```bash
# Check Valkey version
valkey-cli INFO server | grep version

# Must be 9.0 or higher

# Check command availability
valkey-cli COMMAND INFO HSETEX
```

## Additional Resources

- [Valkey Documentation](https://valkey.io/docs/)
- [Valkey GitHub](https://github.com/valkey-io/valkey)
- [Hash Field Expiration Blog](https://valkey.io/blog/hash-fields-expiration/)
- [Numbered Databases Blog](https://valkey.io/blog/numbered-databases/)
- [1 Billion RPS Blog](https://valkey.io/blog/1-billion-rps/)
