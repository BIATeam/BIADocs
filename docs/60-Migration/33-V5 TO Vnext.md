---
sidebar_position: 1
---
# V5 to Vnext

## BIA Framework Migration
 
1. Delete from your Angular projects all **package-lock.json** and **node_modules** folder
2. Use the BIAToolKit to migrate the project : 
   * Run it automatically by clicking on **Migrate** button  
   **or**
   * Execute each step manually until step **3 - Apply Diff**
3. **Mind to check the output logs to check any errors or missing deleted files**
4. Manage the conflicts (two solutions) :
   * Merging rejected files
     * Execute step **4 - Merge Rejected** (already executed with automatic migration)
     * Search `<<<<<` in all files
     * Resolve the conflicts
   * Analyzing rejected files - **MANUAL MIGRATION ONLY**
     * Analyze all the `.rej` files (search "diff a/" in VS code)
     * Apply manually the changes into your files
   :::tip
   Use the [conflict resolution chapter](#conflict-resolution) to help you
   :::
5. For each Angular project, launch the **npm install** and **npm audit fix** command
6. Download the [migration script](./Scripts/V5_to_Vnext_Replacement.ps1)
   1. Change source path of the migration script to target your project root and your Angular project 
   2. Run it for each of your Angular project (change the Angular source path each time)
7. Apply other manual steps for [Front](#front-manual-steps) (for each Angular project) and [Back](#back-manual-steps)
8. Resolve missing and obsolete usings in back-end with BIAToolKit (step **6 - Resolve Usings**)
9. Resolve building issues into your Angular projects and back end
10. If all is ok, you can remove the `.rej` files. During the process they can be useful to resolve build problems
11. Execute the [database migration instructions](#database-migration)
12. For each Angular project, launch the `npm run clean` command
13. Clean back-end solution

# Conflict Resolution

## Front Manual Steps

## Back Manual Steps

## Database Migration