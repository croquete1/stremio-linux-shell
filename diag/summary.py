import sys, re, collections
out = sys.argv[1]
snaps = []
cur = None
for line in open(f"{out}/proc.txt"):
    if line.startswith("## t="):
        cur = (int(line[5:]), {}); snaps.append(cur)
    elif line.startswith("pid=") and cur:
        d = dict(kv.split("=", 1) for kv in line.split())
        cur[1][d["pid"]] = d
if not snaps:
    print("no samples"); sys.exit()
t_first = snaps[0][0]
pids = collections.OrderedDict()
for t, s in snaps:
    for p, d in s.items():
        pids.setdefault(p, []).append((t, d))
for p, rows in pids.items():
    comm = rows[0][1]["comm"]
    fds = [int(d["fds"]) for _, d in rows]
    states = "".join(d["state"] for _, d in rows)
    late = [(t, int(d["ticks"])) for t, d in rows if t - t_first >= 55]
    cpu = (late[-1][1] - late[0][1]) / 100 / max(1, late[-1][0] - late[0][0]) * 100 if len(late) > 1 else float("nan")
    print(f"proc {comm:>18} pid={p} seen={rows[0][0]-t_first}-{rows[-1][0]-t_first}s fds {fds[0]}->{fds[-1]} max={max(fds)} rss_mb={int(rows[-1][1]['rss_kb'] or 0)//1024} cpu_after55s={cpu:.0f}% states={''.join(sorted(set(states)))}")
