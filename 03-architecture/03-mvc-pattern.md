# 03. Model-View-Controller (MVC) Pattern

---

## 1. Definition
**Model-View-Controller (MVC)** is an architectural pattern that divides an application into three interconnected components:
*   **Model**: Encapsulates the application's business data and domain rules.
*   **View**: Renders the user interface and displays data to the user.
*   **Controller**: Receives user input (clicks, keyboard, gestures), processes it (often mutating the Model), and coordinates updates to the View.

---

## 2. Purpose
MVC was the pioneer pattern created to liberate UI systems from monolithic desktop programming in the 1970s. Its purpose is to separate how data is stored and calculated (Model) from how it is displayed (View), enabling changes to the visual look without rewriting business rules.

---

## 3. Why It Matters
*   **Historical Foundation**: Understanding MVC is essential because nearly all modern patterns (MVP, MVVM, MVI) are evolutionary improvements designed to solve specific failure modes of MVC in mobile and modern web apps.
*   **Web Framework Standard**: MVC remains the dominant, highly productive pattern for server-rendered web applications (Ruby on Rails, Spring Boot MVC, Django, ASP.NET MVC).

---

## 4. When to Use It
*   **Server-Side Web Backends**: Excellent fit where incoming HTTP requests hit a Controller, fetch data from a Database Model, and render a HTML View template.
*   **Simple Utilities / CLI Tools**: Where a controller takes CLI arguments, mutates data, and prints output.

---

## 5. When NOT to Use It (Anti-Complexity Limits)
*   **Modern Android Development**: In native Android, `Activity` and `Fragment` classes represent both the View and the Controller. Naive MVC turns activities into 2,000-line "Massive View Controllers" that hold lifecycle listeners, database queries, and view bindings, making them untestable. Use **MVVM** instead.
*   **Declarative Reactive UI**: Modern declarative UI frameworks (Jetpack Compose, React, Flutter) use state-driven reactive rendering, where traditional controllers are completely obsolete.

---

## 6. Advantages & Disadvantages

| Advantages | Disadvantages (in Mobile / Frontend) |
| :--- | :--- |
| **Simple Mental Model**: Input $\rightarrow$ Controller $\rightarrow$ Model $\rightarrow$ View. | **Tight Coupling**: View and Controller are often tightly coupled. |
| **High Backend Productivity**: Unmatched speed in server web frameworks. | **Massive View Controller**: Controller becomes a bloated junkyard. |
| **Separates Business Data**: Model remains independent of UI layout. | **Untestable UI Logic**: Hard to test controller independently of UI lifecycles. |

---

## 7. Practical Examples

```
       User Action (clicks, inputs)
                  │
                  ▼
          ┌──────────────┐
          │  Controller  │
          └──────┬───────┘
                 │ Updates
                 ▼
          ┌──────────────┐  Notifies / Re-renders   ┌──────────────┐
          │    Model     │ ───────────────────────> │     View     │
          └──────────────┘                          └──────────────┘
```

### Classic Backend Controller Example (Spring / Ktor style)
```kotlin
// MODEL
data class Task(val id: String, val title: String, val isCompleted: Boolean)

// CONTROLLER: Handles HTTP input, updates model, routes to template
class TaskController(private val taskService: TaskService) {
    fun handleCompleteTask(taskId: String): HttpResponse {
        val updated = taskService.markCompleted(taskId)
        return if (updated) {
            HttpResponse.Redirect("/tasks/view")
        } else {
            HttpResponse.BadRequest("Task not found")
        }
    }
}
```

---

## 8. Common Mistakes
1.  **Using MVC in Modern Android**: Treating `MainActivity` as the Controller and writing database queries inside `onCreate()`.
2.  **Fat Controllers**: Placing heavy business calculations inside the Controller instead of keeping the Model rich and the Controller thin.
3.  **Two-Way Spaghetti**: Allowing the View to directly mutate the Controller while the Controller directly mutates the View in uncoordinated loops.

---

## 9. Verification Checklist

- [ ] Is the Controller kept thin, delegating business rules to domain services or rich models?
- [ ] Is MVC restricted to appropriate environments (backend web APIs/templates) rather than modern Android UI?
- [ ] Are Views kept free of direct database or network access?
- [ ] Is user input sanitized at the Controller boundary before invoking the Model?
- [ ] Can the Model be tested independently of the View and Controller?
