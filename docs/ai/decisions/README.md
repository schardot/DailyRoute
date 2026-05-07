# ADR Index

This folder contains architectural decision records (ADRs) describing stable project-level decisions and their tradeoffs.

Read relevant ADRs before making significant architectural or gameplay-system changes.

## ADRs

### Autoload singletons as platform services

Describes:

* why autoloads are used
* what belongs in autoloads
* what should remain scene-local

Read when:

* adding global state
* introducing managers/services
* changing scene transition behavior

---

### Systems as runtime-composed services

Describes:

* gameplay systems architecture
* runtime composition
* signal-driven coordination
* orchestration responsibilities

Read when:

* adding gameplay mechanics
* extracting reusable logic
* refactoring scene scripts
* introducing new systems

---

### Scene transitions and handoff via SceneManager

Describes:

* scene transition boundaries
* cross-scene handoff state
* persistence philosophy

Read when:

* modifying transitions
* adding persistence
* changing tutorial/game flow
