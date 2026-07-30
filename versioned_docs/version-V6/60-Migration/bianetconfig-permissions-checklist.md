# bianetconfig Permissions Checklist

After running `migrate-rights-to-permissions.ps1`, verify that every permission name
declared in `bianetconfig*.json` `Names[]` arrays is present as an entry in `PermissionId.cs`.

The migration script only reads `Rights.cs`. Permissions that existed only as strings in
`bianetconfig.json` (never referenced in C# code) are **invisible to the script** and must
be added manually.

## How to check

1. Open each `bianetconfig*.json` in your project.
2. For every `"Names": [...]` array, verify each string exists as an enum value in `PermissionId.cs`.
3. Skip names managed by BIA framework (listed below) — they come from `BiaPermissionId`, not your enum.

## BIA Framework permissions (skip these)

These are provided by `BiaPermissionId` and must NOT be added to the project `PermissionId.cs`:

- `Background_Task_Admin`, `Background_Task_Read_Only`
- `Home_Access`, `Logs_Create`
- `User_List_Access`, `User_List`, `User_List_AD`, `User_Read`, `User_Add`, `User_Delete`, `User_Save`, `User_Sync`, `User_Update_Roles`, `User_Options`
- `Team_List_Access`, `Team_Access_All`, `Team_Options`, `Team_Set_Default_Team`, `Team_Set_Default_Roles`
- `View_Read`, `View_List`, `View_Add_UserView`, `View_Update_UserView`, `View_Delete_UserView`, `View_Delete_TeamView`, `View_Set_Default_UserView`
- `Notification_List_Access`, `Notification_Read`, `Notification_Create`, `Notification_Update`, `Notification_Delete`, `NotificationType_Options`
- `Impersonation_Connection_Rights`
- `Announcement_List_Access`, `Announcement_Create`, `Announcement_Read`, `Announcement_Update`, `Announcement_Delete`, `Announcement_Save`, `AnnouncementType_Options`
- `Roles_Options`, `Roles_List_For_Current_User`, `Roles_List`
- `Permissions_Options`, `LdapDomains_List`, `Languages_Options`, `ProfileImage_Get`
- `App_Member_*`, `Division_Member_*`, `Division_View_*`
- `Back_Admin`, `Back_Read_Only`

## Adding a missing permission

Add the entry to `PermissionId.cs` before the `// BIAToolKit - Begin PermissionId` marker:

```csharp
/// <summary>
/// MyFeature list access.
/// </summary>
MyFeature_List_Access,
```
