# 4-TAP-FIR-FILTER
# FIR Mean Filter — Signed Adders Comparison

This repository implements a 4‑tap signed **Finite Impulse Response (FIR) mean filter** using different adder topologies for the arithmetic core. Each version computes the sum of the four most recent signed input samples (`a`, `ar`, `br`, `cr`, `dr`) and outputs a signed `(w+2)`‑bit result.

---

## 📌 Overview

A 4‑tap FIR mean filter computes the average (or sum) of the last four input samples:


This requires efficient signed addition of four values of width `w`. Different adder architectures trade off **speed, area, and complexity** in hardware.

In DSP, adders are fundamental — faster adders improve filter throughput and overall system performance. :contentReference[oaicite:0]{index=0}

---

## 🧱 1) Ripple Carry Adder (Vanilla)

**Concept:**  
A ripple carry adder (RCA) builds an n‑bit adder by cascading full adders for each bit position. Each full adder waits for the carry from the previous bit before producing its sum. :contentReference[oaicite:1]{index=1}

**Characteristics:**

- Very simple and easy to implement.
- Carry ripples from LSB to MSB, making it **slow for wide operands**.
- Minimal logic area and gate count.

**Use in FIR:**  
The four samples are added sequentially using ripple adders, forming the simplest baseline filter.

---

## ⚡ 2) Carry Look‑Ahead Adder (CLA)

**Concept:**  
A CLA reduces delay by computing **generate (G)** and **propagate (P)** signals so that carry values are determined ahead of time instead of waiting for ripple propagation. :contentReference[oaicite:2]{index=2}

**Generate:** `G_i = A_i & B_i`  
**Propagate:** `P_i = A_i ^ B_i`  

Carry bits are computed in parallel using these signals, reducing the critical path to **O(log n)** rather than O(n). :contentReference[oaicite:3]{index=3}

**Characteristics:**

- Faster than ripple adders.
- More complex control logic.
- Better speed for wide operand widths.

**Use in FIR:**  
Used to accelerate the intermediate additions within the FIR adder block.

---

## 🧮 3) Carry Save Adder (CSA)

**Concept:**  
Carry‑save adders efficiently add **three or more operands** by producing two partial results: a sum vector and a carry vector. These are not fully resolved sums — final addition is done later. :contentReference[oaicite:4]{index=4}

In a CSA, each bit position uses a full adder:

Carry bits are stored in a separate vector and only added (shifted) at the final stage. :contentReference[oaicite:5]{index=5}

**Characteristics:**

- Excellent for reducing multiple operands without waiting for carry propagation.
- Used extensively in multipliers and multi‑operand accumulation.
- Helps reduce overall delay when combining many values.

**Use in FIR:**  
Used to reduce the four operands (`ar`, `br`, `cr`, `dr`) into two vectors before the final sum.

---

## 🔀 4) Carry Select Adder (CSelA)

**Concept:**  
Carry select adders speed up addition by computing two results for each block of bits:  
- one assuming carry‑in = 0  
- one assuming carry‑in = 1  

Once the actual carry‑in is known, the correct result is selected via multiplexers. :contentReference[oaicite:6]{index=6}

**Characteristics:**

- Improved speed compared with pure ripple adders.
- More hardware (duplicate logic for both carry cases).
- Good trade‑off between area and speed.

**Use in FIR:**  
Each addition stage precomputes partial results for fast selection once carry data propagates.

---

## 📊 Summary

| Adder Type | Speed | Area/Complexity | Notes |
|------------|------:|----------------:|-------|
| **Ripple Carry** | Slowest | Smallest | Baseline implementation |
| **Carry Look‑Ahead** | Fast | Higher | Reduces carry propagation delay |
| **Carry Save** | High for multi‑operand | Moderate | Excellent for reducing 4 inputs |
| **Carry Select** | Moderate‑Fast | Higher | Precomputed results, fast select |

Each adder trades off performance and complexity differently. The CLA and CSA designs aim for faster carry resolution, while ripple and carry‑select are simpler or more balanced solutions. :contentReference[oaicite:7]{index=7}

---

## 🧠 Notes

- All designs assume signed arithmetic and proper bit‑width extension.
- FIR filter behavior has been verified against a golden model.
- Choice of adder topology directly influences the clock frequency and latency of the FIR filter.

---

Feel free to customize this document with **diagram examples**, **simulation waveforms**, or **synthesis results** for area/timing comparisons.
::contentReference[oaicite:8]{index=8}


