PRO – Showcase
==============

This repository contains a **showcase subset** of the PRO iOS app codebase, focused on:

- Onboarding and main navigation SwiftUI views
- Core app entry point
- Core Data stack and model structure

## Structure

- `Views/`
  - High-level SwiftUI screens such as:
    - App entry (`PRO_version_0_0App.swift`)
    - Splash / waiting / onboarding flow
    - Main tab and main page
    - Training dashboard and key workout views (list, detail, monthly summary)

- `CoreData/`
  - `PersistenceController.swift` – Core Data stack setup
  - `WorkoutModel.xcdatamodeld/` – Core Data model (entities, attributes, relationships)
  - `*Entity+CoreDataClass.swift` / `*Entity+CoreDataProperties.swift` – generated NSManagedObject subclasses
  - Supporting model types such as `SportType`

## Demo Video

<video src="https://github.com/Maria-Nik/PRO_showcase/raw/main/PRO_showcase/media/pro-demo.mp4" controls width="360"></video>

## Notes

- This repo is **code-only for reference** and is not intended to be a fully buildable app by itself.
- Sensitive configuration, assets, and other private project files are intentionally omitted.
