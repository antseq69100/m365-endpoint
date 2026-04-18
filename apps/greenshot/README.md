# Greenshot - Intune Win32 deployment with PSAppDeployToolkit (Portable ZIP)

## Objective
Deploy Greenshot 1.3.315 through Microsoft Intune as a Win32 app using PSAppDeployToolkit and the portable ZIP package, with a fully silent user-context deployment, clean removal, and reliable detection.

## Target version
`1.3.315`

## Chosen method
- Intune Win32 package
- PSAppDeployToolkit (PSADT)
- Deployment in **User** context
- Source based on the **portable ZIP package**
- Files copied to `%LocalAppData%\Programs\Greenshot`
- Detection through a custom **HKCU** registry marker
- Optional startup registration through `HKCU\Software\Microsoft\Windows\CurrentVersion\Run`
- Pilot validation before wider deployment

## Source package
Use the extracted contents of:

`Greenshot-PORTABLE-1.3.315-RELEASE.zip`

Do not package the ZIP file itself.  
Do not use the standard Greenshot EXE installer for this deployment model.

## Package structure

```text
Greenshot-PSADT/
├─ Invoke-AppDeployToolkit.ps1
├─ PSAppDeployToolkit/
└─ Files/
   ├─ Greenshot/
   │  ├─ Greenshot.exe
   │  ├─ Greenshot.Base.dll
   │  ├─ Greenshot.Editor.dll
   │  ├─ Languages/
   │  ├─ Plugins/
   │  └─ ...
   └─ greenshot-defaults.ini
