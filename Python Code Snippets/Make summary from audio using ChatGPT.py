import whisper
import openai
import textwrap
import pyperclip


model = whisper.load_model("medium")
result = model.transcribe("/Users/sheldon/Downloads/sample.mp3")

print(result["text"])

splitText = textwrap.wrap(result["text"], 3000)

openai.api_key = "[ENTER YOUR API KEY HERE]"

summary = []

for text in splitText: 
    completion = openai.Completion.create(
        engine="text-davinci-003",
        prompt="Summarize the following text for me:  '{}'".format(text),
        max_tokens=1024,
        n=1,
        stop=None,
        temperature=0.5,
    )
    summary.append((completion.choices[0].text))

print(summary)

pyperclip.copy(" ".join(summary))

pyperclip.copy(result["text"])