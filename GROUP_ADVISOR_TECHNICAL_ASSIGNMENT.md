# Technical Assignment: Group Advisor

## Goal
Add an `advisor` field for each study group. The advisor is a teacher responsible for the group.

## Business Rules
- A group can have `0 or 1` advisor.
- An advisor must be a valid teacher.
- One teacher can be advisor for multiple groups.
- Only admin users can assign, change, or remove an advisor.
- A group can be created without an advisor.
- Reassigning an advisor replaces the previous one.

## Scope
- Database/model update
- Backend API update
- Admin UI update
- Display advisor in group-related screens

## Backend Requirements

### Data Model
Update group entity/table:
- Add `advisor_id` as nullable foreign key to teacher table

Expected response fields:
- `advisorId`
- `advisorName`
- optional: `advisorEmail`
- optional: `advisorPhone`

### API
Update existing endpoints:
- `GET /groups`
- `GET /groups/{id}`
- `POST /groups`
- `PUT /groups/{id}`

Request payload for create/update:
```json
{
  "name": "Math Grade 7",
  "grade": 7,
  "monthlyFee": 5000,
  "advisorId": 3
}
```

Response example:
```json
{
  "id": 12,
  "name": "Math Grade 7",
  "grade": 7,
  "monthlyFee": 5000,
  "advisorId": 3,
  "advisorName": "Aizada Omurbekova"
}
```

Optional dedicated endpoint if needed:
- `PATCH /groups/{id}/advisor`

### Validation
- Reject nonexistent teacher id
- Reject non-teacher user as advisor
- Allow `advisorId = null`

## Frontend Requirements

### Admin UI
Add advisor support to:
- group create dialog/form
- group edit form
- groups list/cards
- group details screen if present

### UI Behavior
- Field label: `Advisor`
- Dropdown source: teachers list
- Include option: `No advisor`
- Show advisor name in group cards/list
- Empty state text: `No advisor assigned`

## Permissions
- Admin: full access
- Teacher/accountant/student: read-only if group data is visible

## Acceptance Criteria
1. Admin can assign advisor during group creation
2. Admin can change advisor for an existing group
3. Admin can remove advisor from a group
4. Group list shows advisor correctly
5. Group details API returns advisor fields
6. Invalid advisor assignment is rejected by backend
7. Existing groups without advisor continue to work without migration issues

## Nice to Have
- Filter groups by advisor
- Click advisor name to open teacher profile
- Audit log for advisor changes
