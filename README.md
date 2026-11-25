
# Contracts in Verilog: Hardware-Accelerated Jurisprudence

> **Formally verifying commercial and financial contracts using Register-Transfer Level (RTL) architecture, IEEE 1800 SystemVerilog, and open-source Electronic Design Automation (EDA) tooling.**

---

## 🏛️ 1. Philosophy: Law as Silicon Architecture

Most computational law projects (e.g., Catala, L4, Stipula, Solidity) attempt to model legal text in sequential software programming languages. This creates a severe **semantic impedance mismatch**:

1. **Law Operates in Continuous Time:** Real-world contracts govern deadlines, cure periods, and statutes of limitations. Sequential software languages have no native concept of physical time, forcing researchers to resort to artificial boolean flags or discrete snapshot hacks.
2. **Law is Inherently Concurrent:** In any agreement, bilateral rights, reciprocal duties, and third-party liabilities exist **simultaneously in space**. Emulating concurrent legal obligations in single-threaded software creates thread-locking and race conditions.
3. **The Verification Wheel Does Not Need Reinventing:** Instead of spending decades building bespoke academic theorem provers for new legal DSLs, we can leverage **40 years and $50 billion of semiconductor engineering**. The Electronic Design Automation (EDA) industry already solved temporal logic verification.

### The Hardware Mapping:
* **Statutory Exception $\rightarrow$ Priority Multiplexer**
* **Calendar Days / Time-Limits $\rightarrow$ Clock Edge (`posedge clk_day`)**
* **Legal Status $\rightarrow$ Finite State Machine (FSM)**
* **Hohfeldian Rights & Duties $\rightarrow$ Physical Output Busses**
* **Legal Invariants $\rightarrow$ SystemVerilog Assertions (SVA) via SMT Model Checkers**

---

## 🔍 2. Case Study: The Notice-and-Cure Livelock (`buggy_contract.sv`)

`buggy_contract.sv` models a standard commercial SaaS Service Level Agreement (SLA). Every single clause is **100% facially valid, standard boilerplate** under common law:

* **Clause 1 (Payment):** Client shall pay recurring service fees on the final day of each billing cycle. Failure to pay constitutes a Payment Default.
* **Clause 2 (Notice):** Upon default, Provider must serve written notice, initiating a mandatory Grace Period.
* **Clause 3 (Right to Cure):** Client retains the right to cure before the Grace Period expires.
* **Clause 4 (Waiver & Restitution):** Timely cure waives the default and restores the contract to Active status.
* **Clause 5 (Exclusive Termination):** Provider may terminate **if and only if** the Grace Period expires without cure (`cure_timer == 0`).

### The Hidden Defect (The Livelock Loophole):
Because the contract strictly bars termination while a cure is pending or after a cure is tendered, **a chronic defaulter can exploit the agreement forever**:
1. Skip the payment due date on purpose.
2. Wait for the Provider to issue notice.
3. Cure at the final minute of the Grace Period.
4. The contract resets to Active. Repeat every single cycle.

The Provider incurs administrative and legal costs every month, effectively provides a permanent interest-free loan, and **is legally barred from EVER terminating the contract.**

---

## 🧪 3. Formal Verification & Experimental Matrix

We evaluate `buggy_contract.sv` using **SymbiYosys (`sby`)** and the **Z3 SMT solver**. The contract exposes its entire legal standing via Hohfeldian output pins and is evaluated against an independent **Bilateral Commercial Audit Suite**.

### The 3-Act Demonstration:

| Run Configuration | Toggles | `audit_bmc` (Safety) | `audit_cover` (Reachability) | Formal Verification Finding |
| :---: | :--- | :---: | :---: | :--- |
| **1. Naive Boilerplate** | `patch off`<br>`forgot off` | **`PASS`** | **`FAIL`** *(Scenario 3 Unreachable)* | **Loophole Detected:** Z3 proves the Provider's unilateral exit remedy is mathematically unreachable. |
| **2. Rigorous Engineering** | `patch on`<br>`forgot off` | **`PASS`** | **`PASS`** *(All Traces Reached!)* | **Full Harmony:** Clause 5.4 terminates habitual defaulters; livelock is permanently sealed. |
| **3. Sloppy Drafting** | `patch on`<br>`forgot on` | **`FAIL`** *(Step 16 collision)* | **`PASS`** | **Drafting Malpractice:** Lawyer forgot *"Subject to Clause 5.4"*, causing facial right-to-cure contradiction. |

---

## 🚀 4. How to Reproduce

### Prerequisites
Install the [Yosys OSS CAD Suite](https://github.com/yosyshq/oss-cad-suite-build)

### Running the Formal Verification Suite
```bash
# Run both Bounded Model Checking (BMC) and Cover Reachability simultaneously:
sby -f buggy_contract.sby
```

To view the synthesized exploit traces and witness waveforms:
```bash
gtkwave buggy_contract_audit_cover/engine_0/trace0.vcd
```

---

## 🔮 5. Roadmap
* [x] **`buggy_contract.sv`**: Multi-clause commercial SLA notice-and-cure livelock and drafting malpractice verification.
* [ ] **`isda-2002/`**: Translating the **2002 ISDA Master Agreement** (Section 5 Events of Default & Section 6 Early Termination Close-Out Netting) onto synthesizable FPGA logic.

