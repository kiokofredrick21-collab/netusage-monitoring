# NetUsage Hub / PerfMonitor Kenya — Requirements Analysis

## 1. Source documents reviewed

- `Fredrick_Kiokodocs(1).docx`: the network usage/performance monitoring project documentation.
- `PROJECTTEMPLATEDSE-DCS-DIT-DBIT.docx`: a bookstore inventory template used as a documentation structure reference.

## 2. Key inconsistencies to correct in the project report

The first document mixes several unrelated project descriptions. The title and problem statement refer to **NetUsage Hub in Kisii** and network usage monitoring, while the general objective refers to a **manuscript repository**, and some specific objectives refer to manuscript version control and publishing-company workflows. Later chapters switch to **PerfMonitor Kenya** and describe network devices, thresholds, alerts and reports. The second document is a bookstore example using Flask and SQLite, so its implementation details should not be copied into the network-monitoring report.

For a coherent final report, use one name consistently: **NetUsage Hub Network Usage Monitoring System**. Replace the copied manuscript objective with: “To design and implement a centralized network usage monitoring system for NetUsage Hub in Kisii.” Use PHP, MySQL, HTML, CSS and JavaScript consistently in the tools, implementation and deployment chapters.

## 3. Consolidated functional requirements

| Module | Requirement | Implementation status |
|---|---|---|
| Authentication | Administrator logs in securely | Implemented with PHP sessions and password hashing |
| Device management | Add, edit, delete and set device status | Implemented |
| Metrics | Record download, upload, latency and packet loss | Implemented through form and JSON endpoint |
| Thresholds | Compare usage with configured device limits | Implemented for download and upload limits |
| Alerts | Create unresolved alerts when limits are exceeded | Implemented |
| Dashboard | Show device counts, online devices, alerts and traffic | Implemented |
| Reports | Filter by dates and export CSV | Implemented |
| Mobile support | Use the interface on phones and desktop browsers | Responsive CSS implemented |

## 4. Suggested database entities

- **users**: authentication and roles.
- **devices**: monitored routers, switches and access points.
- **usage_metrics**: timestamped network measurements for each device.
- **alerts**: threshold events connected to a device and optional metric.

The relationships are: one device has many usage metrics; one device has many alerts; and an alert may reference the metric that caused it.

## 5. Recommended academic report structure

Use the bookstore template’s four-chapter layout, but rewrite all content around network monitoring:

1. **Chapter One — Project Planning and Analysis:** problem, justification, objectives, functional/non-functional requirements, tools, resources and schedule.
2. **Chapter Two — Design and Modeling:** login UI, dashboard UI, device interface, alert/report interface, flowcharts, DFD, ERD, use case and class diagram.
3. **Chapter Three — System Implementation:** PHP/PDO connection, authentication, device CRUD, metric recording, alert rules, dashboard queries, reporting and testing.
4. **Chapter Four — Conclusion and Recommendation:** achievements, limitations, future work such as SNMP polling, email/SMS notifications, user roles and historical charts.

## 6. Important limitations of this MVP

The JSON metric endpoint currently requires an authenticated PHP session. For deployment on actual routers or monitoring agents, add per-device API keys, HTTPS, request validation and rate limiting. The current metric form demonstrates the business logic; it does not automatically poll network devices using SNMP or vendor APIs.
