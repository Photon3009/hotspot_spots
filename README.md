# hotspot_hosts

## Features

1. **Experience Type Selection Screen**
    - Users can select multiple experiences from a list.
    - Answers can be provided as text in the Onboarding Question Screen.

2. **Onboarding Question Screen**
    - Upon clicking "Next" on the Experience Selection screen, users are navigated to this page.
    - The screen includes a multi-line text field with a character limit of 600.
    - Users can record audio answers.
    - Users can record video answers.
    - The layout adapts dynamically to the design specifications, removing audio and video recording buttons from the bottom if the corresponding asset has already been recorded.

## Implemented Features (Brownie points)
- **BLoC Architecture**: The app uses the BLoC pattern for state management.
- **Dio**: For handling HTTP requests.
- **Animations**:
    - **Experience Screen**: When a card is selected, it animates and slides to the first index.
    - **Question Screen**: The `Next` button width animates when the audio and video recording buttons disappear.

## Demo

Here's a short demo clip showcasing the app's functionalities:  
([URL](https://drive.google.com/file/d/1kMD0IyXaPxJYNq5LfgYimoUYCm_fDFir/view?usp=sharing))
