 # 📡 Netdata Monitoring Setup

> Monitor your server in real-time — CPU, RAM, Disk, Network, and Docker containers.

---

## 🧠 What is Netdata?

Netdata is a free tool that watches your server 24/7 and shows you live graphs of everything happening — how hard the CPU is working, how much memory is being used, how busy the disks are, and how much data is going in and out over the network.

You install it once, open one port, and a live dashboard appears in your browser. No complicated setup. No paid license.

Think of it like a health monitor for your server — always running in the background, always watching, and screaming at you before something breaks.

---
![jenkins](imag/re1.png)
## 🖥️ What It Monitors

| What | What You See |
|------|-------------|
| CPU | How hard each core is working, right now |
| Memory (RAM) | How much is used, free, cached |
| Disk | How fast data is being read and written |
| Network | How much data is flowing in and out |
| Processes | Every program running on your server |
| Docker Containers | CPU and RAM per container individually |
| Alerts | Warnings when something is wrong |

---

## ⚙️ How to Install

There are two ways to install Netdata. Both end up with the same result — a live dashboard on port 19999.

### Way 1 — Install directly on the server

You run the official Netdata install script on your EC2 instance. It figures out your operating system automatically, installs everything it needs, sets itself up as a background service, and starts running. This is the simplest option if you just want Netdata on one server.

### Way 2 — Run as a Docker container

If you already use Docker on your server, you can run Netdata as a container instead of installing it directly. It works exactly the same way — same dashboard, same metrics — but everything stays inside Docker.

For the Docker setup, all the details are in the **DOCKER_INSTALL.md** file in this repo.

---

## 🔌 Port Setup

Netdata's dashboard runs on **port 19999**.

After installing, you open that port in AWS so your browser can reach it. Without this step, the dashboard will not load even though Netdata is running perfectly fine.

### How to open port 19999 in AWS

1. Go to your EC2 instance in the AWS Console
2. Click on the **Security Group** attached to it
3. Click **Inbound Rules** → **Edit inbound rules**
4. Click **Add rule** and fill it in like this:

| Field | Value |
|-------|-------|
| Type | Custom TCP |
| Protocol | TCP |
| Port Range | 19999 |
| Source | Your IP address |

5. Click **Save rules**

Now open your browser and go to `http://YOUR_EC2_PUBLIC_IP:19999` — your dashboard is live.

### Which source should I choose?

| Source Option | When to Use It |
|---------------|---------------|
| My IP only | Best option — only you can see the dashboard |
| Anywhere (0.0.0.0/0) | Anyone on the internet can access it — avoid this |
| Company / VPN IP range | Good for teams — everyone on the same network can access it |

> 💡 For learning and personal projects, just use your own IP. It takes 10 seconds and keeps your server safe.

---

## 🐳 If You Use Docker

When Netdata runs inside a Docker container, it needs a little extra help to see what is happening on the actual server — because by default, containers are isolated from the host.

Here is what needs to happen and why:

**Seeing host metrics (CPU, RAM, Disk, Network)**
Netdata needs to read special Linux system files that live at `/proc` and `/sys` on your server. These files are where the Linux kernel publishes live statistics. When running in Docker, those paths need to be shared with the container so Netdata reads real server data and not just what is inside the container bubble.

**Seeing all running processes**
By default a Docker container only knows about its own processes. Netdata needs to see every process on the whole server — your web server, your database, everything. This is done by telling Docker to share the host's process list with the Netdata container.

**Seeing other Docker containers**
Netdata monitors other containers by talking to the Docker engine through a special file called the Docker socket. If that file is shared with the Netdata container, it can discover every other container automatically and show you their CPU and RAM usage individually.

**Why all those flags and mounts matter**
Each missing piece means a blank section in your dashboard. No socket = no container metrics. No `/proc` mount = no host CPU or memory graphs. No process sharing = no process list. When everything is provided together, Netdata sees the full picture exactly as if it were installed directly on the server.

All the exact commands and files for Docker are in **DOCKER_INSTALL.md**.

---

## 📊 What the Dashboard Looks Like

Once you open `http://YOUR_IP:19999` you will see a dark dashboard with live graphs updating every second.

The left sidebar lets you jump between sections. The main area shows charts — each one is a different metric, and they all move in real time.

At the top right there is a **LIVE** button. When it is green, everything is streaming live. If you click on a chart to zoom in, the dashboard pauses. Click LIVE again to go back to real time.

If you ever see **"No charts to display"** — click the LIVE button. That fixes it almost every time.

---

## 🔔 Alerts

Netdata comes with over 200 built-in alert rules ready to go the moment you install it. You do not have to configure anything for basic alerting — it starts watching and will let you know when something looks wrong.

**What kinds of things trigger alerts:**

- CPU has been above 90% for more than a minute
- RAM is almost full and the server is about to start swapping
- A disk is almost full — this one causes sudden crashes if missed
- Network traffic spiked to an unusual level
- A Docker container was killed because it ran out of memory
- Netdata itself stopped collecting data (means the server might be down)

**How you get notified:**

You can set up Netdata to send alerts to Email, Slack, PagerDuty, Discord, or Telegram. All notification settings are in one config file. You turn on the channel you want, paste in your webhook URL or email address, and save. That is it.

---

## ☁️ Netdata Cloud (Optional)

Netdata Cloud is a free website at `app.netdata.cloud` where you can see all your servers in one place. Instead of opening a separate browser tab for each server, you log into the cloud and see everything together.

The agent on your server connects outward to the cloud over HTTPS. You do not need to open any extra ports for this — it is all outbound.

To connect, you get a token from the cloud website and run one command on your server that registers it. Within about a minute your server appears in the cloud dashboard.

**One important thing to know:** if your cloud dashboard shows no data, always check the local dashboard first at `http://YOUR_IP:19999`. If local works fine, the issue is just the cloud connection — not Netdata itself.

---

## 🔒 Keeping It Secure

A few simple things that make a big difference:

**Restrict who can reach port 19999** — Set the Security Group source to your IP only, not the whole internet. This is the single most important step.

**Put a password on it** — If you need the dashboard accessible to a team, put Nginx in front of Netdata and add HTTP basic authentication. Then only people with the password can open the dashboard.

**Bind to localhost** — You can configure Netdata to only listen on the local network interface, not the public one. Then nothing external can reach it directly, and all traffic goes through your proxy. This is the most secure setup for production.

---

## 🧪 Something Not Working?

| Problem | Fix |
|---------|-----|
| Dashboard URL does not load | Port 19999 is not open — check your AWS Security Group inbound rules |
| "No charts to display" | Click the LIVE button in the top right corner |
| Docker container metrics are missing | The Docker socket is not shared with Netdata — see DOCKER_INSTALL.md |
| Host CPU/RAM missing in Docker setup | The `/proc` and `/sys` mounts are missing from the container |
| Process list is empty in Docker setup | The `--pid=host` flag is missing |
| Netdata Cloud shows node offline | Run the claim command again on your server |
| Dashboard loads but shows old data | The Netdata service stopped — restart it with systemctl or docker restart |

---

## 🔗 Links

| Resource | Link |
|----------|------|
| Official Docs | https://learn.netdata.cloud |
| GitHub | https://github.com/netdata/netdata |
| Netdata Cloud | https://app.netdata.cloud |
| Community | https://community.netdata.cloud |

---

## 👨‍💻 About This Project

Built for learning DevOps and server monitoring on AWS EC2.
Covers native install, Docker setup, alerting, cloud integration, and security basics.
 ---
👩‍🏫 **Guided and Supported by [Trupti Mane Ma’am](https://github.com/iamtruptimane)**  
---

👨‍💻 **Developed By:**  
**Shivam Garud**  
🧠 *DevOps & Cloud Enthusiast*  
💼 *Automating deployments, one pipeline at a time!*  
🌐 [GitHub Profile](https://github.com/Shivamgarud8)
🌐 [Medium blog](https://medium.com/@shivam.garud2011)
🌐 [linkedin](www.linkedin.com/in/shivam-garud)
🌐 [portfolio](https://shivam-garud.vercel.app/)

