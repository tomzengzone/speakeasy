local now = tonumber(ARGV[1])
local states = {}
local allowed = 1
local max_retry_seconds = 0
local violated_index = 0

for index, key in ipairs(KEYS) do
  local offset = 2 + ((index - 1) * 3)
  local capacity = tonumber(ARGV[offset])
  local refill_tokens = tonumber(ARGV[offset + 1])
  local refill_period_ms = tonumber(ARGV[offset + 2])
  local values = redis.call('HMGET', key, 'tokens', 'updated_at')
  local tokens = tonumber(values[1]) or capacity
  local updated_at = tonumber(values[2]) or now
  local elapsed = math.max(0, now - updated_at)
  tokens = math.min(capacity, tokens + ((elapsed / refill_period_ms) * refill_tokens))
  local retry_seconds = 0
  if tokens < 1 then
    allowed = 0
    retry_seconds = math.ceil((((1 - tokens) * refill_period_ms) / refill_tokens) / 1000)
    if retry_seconds > max_retry_seconds then
      max_retry_seconds = retry_seconds
      violated_index = index
    end
  end
  states[index] = { key, tokens, capacity, refill_tokens, refill_period_ms }
end

for index, state in ipairs(states) do
  local tokens = state[2]
  if allowed == 1 then tokens = tokens - 1 end
  redis.call('HSET', state[1], 'tokens', tokens, 'updated_at', now)
  local ttl = math.ceil((state[3] / state[4]) * state[5]) + 60000
  redis.call('PEXPIRE', state[1], ttl)
end

return { allowed, max_retry_seconds, violated_index }
