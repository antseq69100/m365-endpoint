# Autopilot deployment flow

1. Device hardware hash imported into Windows Autopilot service

2. Device automatically added to dynamic group:
(device.devicePhysicalIDs -any (_ -contains "[ZTDId]"))

3. Autopilot deployment profile assigned:
Azure AD Join
User-driven mode
Standard user rights

4. Device renamed using naming convention:
AP-LAB-VM-%SERIAL%
AP-LAP-%SERIAL%
AP-DSK-%SERIAL%

5. Enrollment Status Page (ESP) starts:
Required security configuration applied

6. Security baseline deployed:
BitLocker
Defender
Firewall configuration

7. Required applications installed:
Company Portal
Core applications
Lab test applications

8. Device ready for user sign-in
