# Incident Report Template

> Post-broadcast incident documentation for continuous improvement.

---

## Incident Information

| Field | Value |
|-------|-------|
| **Date** | <!-- YYYY-MM-DD --> |
| **Time** | <!-- HH:MM (when incident occurred) --> |
| **Duration** | <!-- How long the incident lasted --> |
| **Severity** | <!-- Critical / Major / Minor --> |
| **Stream/Event** | <!-- Name of the stream or event --> |
| **Reported By** | <!-- Your name --> |

### Severity Definitions

| Level | Definition | Examples | Response Time |
|-------|------------|----------|---------------|
| **Critical** | Stream is down or completely unusable; viewers cannot watch | Complete audio/video loss, platform disconnection, system crash, encoding failure | Immediate (drop everything) |
| **Major** | Significant quality degradation affecting viewer experience | Persistent frame drops (>5%), audio sync issues, single camera failure, visible artifacts | Within 2 minutes |
| **Minor** | Noticeable issues that don't significantly impact viewing | Momentary glitches (<10s), minor audio level fluctuation, brief frame stutter, cosmetic issues | When convenient (don't interrupt flow) |

**Severity Selection Guide:**
- If viewers are complaining or leaving → **Critical**
- If the issue is visible/audible but stream continues → **Major**
- If you noticed it but viewers likely didn't → **Minor**

---

## Incident Summary

<!-- One paragraph summary of what happened -->



---

## Timeline

| Time | Event |
|------|-------|
| <!-- HH:MM --> | <!-- What happened --> |
| <!-- HH:MM --> | <!-- What happened --> |
| <!-- HH:MM --> | <!-- Resolution or stream end --> |

---

## Impact

### Viewer Impact

- [ ] Stream went offline
- [ ] Video quality degraded
- [ ] Audio quality degraded
- [ ] Visible errors/artifacts
- [ ] No viewer-facing impact

**Estimated affected duration:** <!-- minutes/seconds -->

**Approximate viewer count at time of incident:** <!-- if known -->

### Production Impact

- [ ] Had to switch to backup
- [ ] Lost content (not recorded)
- [ ] Required restart of software
- [ ] Required restart of hardware
- [ ] Required manual intervention

---

## Technical Details

### System State

**Hardware involved:**
- [ ] DeckLink/Video capture
- [ ] MOTU/Audio interface
- [ ] Cameras
- [ ] Network equipment
- [ ] Mac Studio
- [ ] Other: <!-- specify -->

**Software involved:**
- [ ] OBS Studio
- [ ] Ableton Live
- [ ] Dante Controller
- [ ] Blender
- [ ] Other: <!-- specify -->

### Error Messages

<!-- Copy any error messages, warnings, or log entries -->

```
[Paste error messages here]
```

### System Resources at Time of Incident

<!-- If available from Activity Monitor or OBS Stats -->

| Metric | Value |
|--------|-------|
| CPU Usage | <!-- % --> |
| Memory Used | <!-- GB --> |
| Disk Space | <!-- GB free --> |
| OBS Dropped Frames | <!-- count --> |
| Encoding Bitrate | <!-- kbps --> |

---

## Root Cause Analysis

### What happened?

<!-- Detailed technical description -->



### Why did it happen?

<!-- Root cause identification -->



### Could it have been prevented?

<!-- Yes/No + explanation -->



### Were there warning signs?

<!-- Any indicators that could have predicted this -->



---

## Resolution

### Immediate Actions Taken

<!-- What was done to resolve the incident during the stream -->

1.
2.
3.

### Was the resolution successful?

<!-- Yes/No + details -->



---

## Follow-Up Actions

### Preventive Measures

<!-- Actions to prevent recurrence -->

| Action | Owner | Due Date | Status |
|--------|-------|----------|--------|
| <!-- Action item --> | <!-- Name --> | <!-- Date --> | ⏳ Pending |
| <!-- Action item --> | <!-- Name --> | <!-- Date --> | ⏳ Pending |

### Documentation Updates

<!-- Which documents need to be updated -->

- [ ] RUNBOOK.md - Add check for <!-- specific check -->
- [ ] TROUBLESHOOTING.md - Add section for <!-- specific issue -->
- [ ] health-check.sh - Add validation for <!-- specific validation -->
- [ ] Other: <!-- specify -->

### Equipment/Software Changes

<!-- Any hardware or software changes recommended -->

- [ ] None required
- [ ] Upgrade/replace: <!-- specify -->
- [ ] Add redundancy: <!-- specify -->
- [ ] Change configuration: <!-- specify -->

---

## Lessons Learned

### What went well?

<!-- What worked during incident response -->

-
-

### What could be improved?

<!-- Areas for improvement -->

-
-

### Key takeaways

<!-- Main lessons for the team -->

1.
2.
3.

---

## Attachments

<!-- List any relevant files -->

- [ ] OBS log file: <!-- filename -->
- [ ] Screenshot: <!-- filename -->
- [ ] Stream recording segment: <!-- filename/timestamp -->
- [ ] Other: <!-- specify -->

---

## Sign-Off

| Role | Name | Date |
|------|------|------|
| Incident Reporter | <!-- Name --> | <!-- Date --> |
| Technical Review | <!-- Name --> | <!-- Date --> |
| Actions Verified | <!-- Name --> | <!-- Date --> |

---

*Template version: 1.0.0*
