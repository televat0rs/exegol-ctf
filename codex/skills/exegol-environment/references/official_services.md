# Official: services list

From Exegol docs (`images/services.md`).

| Service | Port(s) | Commands | Comments |
|---|---:|---|---|
| **neo4j** | 7687, 7474, 7373 | `neo4j start`, `neo4j stop`, `neo4j restart` | Used by BloodHound and related tools. |
| **BloodHound-CE** | 1030 | `bloodhound-ce`, `bloodhound-ce-reset`, `bloodhound-ce-stop` | BloodHound Community Edition web interface. |
| **postgresql** | 5432 | `service postgresql [...]` | Used by BloodHound CE. |
| **Burp Suite** | 8080 | `burpsuite` | HTTP(S) proxy. |
| **Starkiller (Empire)** | TBD | `ps-empire server` | GUI for Empire. |
| **Havoc** | 40056 | `havoc client/server` | C2 framework. |

