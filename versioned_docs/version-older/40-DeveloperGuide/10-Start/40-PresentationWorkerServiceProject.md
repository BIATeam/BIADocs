---
sidebar_position: 1
---

# Presentation Worker service project
**Since V3.7.0 the worker service is a windows service. Before it was an application pool**
## Prepare the Worker service (>=V3.7.0):
1. Compile the solution 
- Set Worker service as startup project
- Launch it

## Prepare the Worker service Site (\<V3.7.0):
1. Compile the solution 
- Set Worker service as startup project
- Launch it a first time with IIS

2. Open IIS manager. 
- Set the physical path of the Folder (with the name of the application [ProjectName]) to d:\www\[ProjectName] (in basic settings)
- On the [ProjectName]\WorkerService site :
    - Open Basic setting 
    - Note the name of the application pool (automatically created by Visual studio during the first run)
    - Move the Wep Api Application Pool to an other one (no importance of witch one it is temporary)
- In Application Pool 
    - Rename the automatically created application pool to [ProjectName]WorkerService
    - The pool must be in "No Managed Code".
    - In advanced settings > identity Set an account, you have 2 options:
      - Your user account (you will change the pass every time you update it) 
      - Use a Service account which have sufficient rights on AD. If you choose this option, don't forget to allow this user to access your database in SQL Server Management Studio.
- On the [ProjectName]\WepApi site :
    - Open Basic setting 
    - Move the Wep Api Application Pool to [ProjectName]WorkerService
    - Verify the authentication : Anonymous and windows authentication should be enable.

3. Restart Visual Studio
- Close Visual Studio
- Restart Visual Studio and open the solution
- Launch it with IIS

