---
sidebar_position: 1
---

# Create your first Team
This page will explains how to create a team inside your project.

## Prerequisites
We will create in first the team 'Company' in back-end.
### Create the DTO
1. Open with Visual Studio 2022 the solution **'...\MyFirstProject\DotNet\MyFirstProject.sln'**.
2. In **'...\MyFirstProject\DotNet\MyCompany.MyFirstProject.Domain.Dto'** create **'Company'** folder.
3. Create empty class **'CompanyDto.cs'** and add following:
```csharp
// <copyright file="CompanyDto.cs" company="MyCompany">
// Copyright (c) MyCompany. All rights reserved.
// </copyright>

namespace MyCompany.MyFirstProject.Domain.Dto.Company
{
    using BIA.Net.Core.Domain.Dto.User;

    /// <summary>
    /// The DTO used to represent a company.
    /// </summary>
    public class CompanyDto : TeamDto
    {
        /// <summary>
        /// Gets or sets the company name.
        /// </summary>
        public string CompanyName { get; set; }
    }
}

```
Make sure to inherit from `TeamDto`.
### Create the Model
1. In **'...\MyFirstProject\DotNet\MyCompany.MyFirstProject.Domain'** create **'CompanyModule'** folder, then create a folder **'Aggregate'** into it.
2. Create empty class **'Company.cs'** and add following:
```csharp
// <copyright file="Company.cs" company="MyCompany">
// Copyright (c) MyCompany. All rights reserved.
// </copyright>

namespace MyCompany.MyFirstProject.Domain.CompanyModule.Aggregate
{
    using MyCompany.MyFirstProject.Domain.UserModule.Aggregate;

    /// <summary>
    /// The company entity.
    /// </summary>
    public class Company : Team
    {
        /// <summary>
        /// Gets or sets the company name.
        /// </summary>
        public string CompanyName { get; set; }
    }
}

```
Make sure to inherit from `Team`.

### Create the Mapper
1. Stay in **'...\MyFirstProject\DotNet\MyCompany.MyFirstProject.Domain\CompanyModule\Aggregate'** folder.
2. Create empty class **'CompanyMapper.cs'** and add following:
```csharp
// <copyright file="Company.cs" company="MyCompany">
// Copyright (c) MyCompany. All rights reserved.
// </copyright>

namespace MyCompany.MyFirstProject.Domain.CompanyModule.Aggregate
{
    using System;
    using System.Collections.Generic;
    using System.Linq;
    using System.Linq.Expressions;
    using System.Security.Principal;
    using BIA.Net.Core.Domain.Authentication;
    using MyCompany.MyFirstProject.Crosscutting.Common.Enum;
    using MyCompany.MyFirstProject.Domain.Dto.Company;
    using MyCompany.MyFirstProject.Domain.UserModule.Aggregate;

    /// <summary>
    /// The mapper used for company.
    /// </summary>
    public class CompanyMapper : TTeamMapper<CompanyDto, Company>
    {
        /// <summary>
        /// Initializes a new instance of the <see cref="CompanyMapper"/> class.
        /// </summary>
        /// <param name="principal">The principal.</param>
        public CompanyMapper(IPrincipal principal)
            : base(principal)
        {
            this.UserRoleIds = (principal as BiaClaimsPrincipal).GetRoleIds();
            this.UserId = (principal as BiaClaimsPrincipal).GetUserId();
        }

        /// <inheritdoc cref="TTeamMapper{TTeamDto, TTeam}"/>
        public override Expression<Func<Company, CompanyDto>> EntityToDto()
        {
            return entity => new CompanyDto
            {
                Id = entity.Id,
                Title = entity.Title,
                CompanyName = entity.CompanyName,

                // Should correspond to TTeam_Update permission (but without use the roles *_Member that is not determined at list display)
                CanUpdate =
                    this.UserRoleIds.Contains((int)RoleId.Admin),

                // Should correspond to TTeam_Member_List_Access (but without use the roles *_Member that is not determined at list display)
                CanMemberListAccess =
                    this.UserRoleIds.Contains((int)RoleId.Admin) ||
                    entity.Members.Any(m => m.UserId == this.UserId),
            };
        }

        /// <inheritdoc cref="TTeamMapper{TTeamDto, TTeam}"/>
        public override void DtoToEntity(CompanyDto dto, Company entity)
        {
            base.DtoToEntity(dto, entity);
            entity.CompanyName = dto.CompanyName;
        }
    }
}


```
Make sure to inherit from `TTeamMapper<TTeamDto, TTeam>` and overrides mentionned methods.

### Prepare the database

## Generate Team 

### Using BIAToolKit

### Customize generated files

### Update the database

## Testing your Team
