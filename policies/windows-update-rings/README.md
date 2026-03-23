# Windows Update Rings (WUFB) Strategy

## Overview

This tenant uses a staged Windows Update for Business deployment strategy based on four deployment rings:

| Ring  | Purpose          | Devices               |
| ----- | ---------------- | --------------------- |
| Ring0 | IT validation    | Lab VMs               |
| Ring1 | Pilot users      | Test devices          |
| Ring2 | Broad deployment | Standard users        |
| Ring3 | Production       | Critical workstations |

Feature Updates are controlled separately using Feature Update Policies.

---

# Ring0 – WUFB-RING0-IT

Purpose:

Immediate validation of Windows quality updates before broader rollout.

Settings:

Quality deferral: 0 days
Feature deferral: 0 days
Drivers: Blocked
Deadline quality: 2 days
Deadline feature: 2 days
Grace period: 1 day
Auto reboot before deadline: Enabled

Assigned group:

AP-LAB-WIN-VM

---

# Ring1 – WUFB-RING1-PILOT

Purpose:

Functional validation on pilot users before broad deployment.

Settings:

Quality deferral: 2 days
Feature deferral: 0 days
Drivers: Blocked
Deadline quality: 3 days
Deadline feature: 3 days
Grace period: 1 day
Auto reboot before deadline: Enabled

---

# Ring2 – WUFB-RING2-BROAD

Purpose:

Deployment to majority of production devices.

Settings:

Quality deferral: 5 days
Feature deferral: 0 days
Drivers: Blocked
Deadline quality: 5 days
Deadline feature: 5 days
Grace period: 2 days
Auto reboot before deadline: Enabled

---

# Ring3 – WUFB-RING3-PROD

Purpose:

Deployment to critical production devices after validation.

Settings:

Quality deferral: 7 days
Feature deferral: 0 days
Drivers: Blocked
Deadline quality: 7 days
Deadline feature: 7 days
Grace period: 2 days
Auto reboot before deadline: Enabled

Assigned group:

AP-PROD-WIN*
# Windows Update Rings (WUFB) Strategy

## Overview

This tenant uses a staged Windows Update for Business deployment strategy based on four deployment rings:

| Ring  | Purpose          | Devices               |
| ----- | ---------------- | --------------------- |
| Ring0 | IT validation    | Lab VMs               |
| Ring1 | Pilot users      | Test devices          |
| Ring2 | Broad deployment | Standard users        |
| Ring3 | Production       | Critical workstations |

Feature Updates are controlled separately using Feature Update Policies.

---

# Ring0 – WUFB-RING0-IT

Purpose:

Immediate validation of Windows quality updates before broader rollout.

Settings:

Quality deferral: 0 days
Feature deferral: 0 days
Drivers: Blocked
Deadline quality: 2 days
Deadline feature: 2 days
Grace period: 1 day
Auto reboot before deadline: Enabled

Assigned group:

AP-LAB-WIN-VM

---

# Ring1 – WUFB-RING1-PILOT

Purpose:

Functional validation on pilot users before broad deployment.

Settings:

Quality deferral: 2 days
Feature deferral: 0 days
Drivers: Blocked
Deadline quality: 3 days
Deadline feature: 3 days
Grace period: 1 day
Auto reboot before deadline: Enabled

---

# Ring2 – WUFB-RING2-BROAD

Purpose:

Deployment to majority of production devices.

Settings:

Quality deferral: 5 days
Feature deferral: 0 days
Drivers: Blocked
Deadline quality: 5 days
Deadline feature: 5 days
Grace period: 2 days
Auto reboot before deadline: Enabled

---

# Ring3 – WUFB-RING3-PROD

Purpose:

Deployment to critical production devices after validation.

Settings:

Quality deferral: 7 days
Feature deferral: 0 days
Drivers: Blocked
Deadline quality: 7 days
Deadline feature: 7 days
Grace period: 2 days
Auto reboot before deadline: Enabled

Assigned group:

AP-PROD-WIN*

