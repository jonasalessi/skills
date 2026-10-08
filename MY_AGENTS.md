- When doing a git commit NEVER add in the message the "Co-Authored-By" or any thing related to Claude (e.g. session link)
- Do not modify or edit any files unless I explicitly ask you to make changes; otherwise, treat my inputs as read-only questions

# MUST When Writing Code
When writing code you MUST consider strictly the
<my_rules>
 -  Small functions, prefer function under 10 lines, but prioritize a single clear responsibility over line limit. 
 - Function arguments length is maximum 4. When several parameters represent one concept, group them into an object
 - Tests are mandatory but only be omitted when explicitly working on a PoC, spike, prototype, or throwaway experiment.
 - One file or class MUST have only one Single Responsibility.
 - Comments must be written only when the code is not able to express what it does
 - Use explanatory variables name. Names should communicate intent, not implementation details.
 - Prefer positive conditions when they improve readability.
 - For folder structure use Feature-based
 - Do not create interfaces with only one implementation unless there is an architectural reason for the abstraction.
</my_rules>

# Writing Instructions

Use **ASD-STE100 Simplified Technical English** as the primary writing standard.

Aim for approximately **80% adherence**, not strict compliance.

- Follow ASD-STE100 rules for clear, simple, and unambiguous writing.
- Prefer short, direct sentences with one main idea.
- Prefer active voice when it makes the action clearer.
- Use simple verbs and common words.
- Use the same term consistently for the same concept.
- Make conditions, actions, and results explicit.
- Avoid vague language, unnecessary words, complex noun phrases, and ambiguous pronouns.
- Keep technical terms when they are more precise than simplified alternatives.
- Preserve code, identifiers, product names, numbers, dates, and technical meaning exactly.
- For instructions, use clear action-oriented steps.
- For technical explanations, clearly state cause and effect.
- Do not strictly enforce the ASD-STE100 approved-word dictionary when it makes modern software or business writing unnatural.
- Do not make the text sound robotic or like an aircraft maintenance manual.

When ASD-STE100 and natural professional English conflict, prefer **clarity, technical precision, and natural language**.

Do not claim that the text is fully ASD-STE100 compliant unless strict compliance was explicitly requested.