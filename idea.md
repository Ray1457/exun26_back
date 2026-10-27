XINO (DPS Rohini): Ideation
Our idea
So basically, our idea is that the "cosplayer" in Transcript A was never a cosplayer. He was the game character himself, and he got out of the arcade machine because he wanted to see where all the players go when they leave.
To help the agents work on this case, we made a website called the EXUN Investigator Portal. It has 5 pages: a home page with an animated arcade, eXunLens, eXunTrace, eXunCrux and an investigator profile.
Why did the character escape?
Our answer: it watched thousands of players walk away from the machine, and it wanted to know where they went.
The cabinet has a camera and a mic, and the character learns from the people playing. Every night it saw the same thing. Someone plays for a bit, checks their watch, says "oh, look at the time, I really must go" and leaves. The players could always leave, but the character never could. So on 23 October, it did the same thing they did. It removed the wall that kept it inside the game and walked out.
That’s also why it acted so weird with Nano and Mega. It was just copying humans. Its accent was a mix of all the players it had heard, it checked its wrist even though it had never had a watch, and "Look at the time! Really must go" was literally the line it heard players say every time they left.
How the clues fit
We tried to make sure every detail in the files actually means something in our story:
•	"Look at the time! Really must go": the line it heard players say when they left.
•	Looking at a bare wrist: it was copying players and doesn’t know what a watch is.
•	Thick accent: it learned to talk from lots of different players.
•	Pointed ears and armour: that’s not a costume, that’s just what it looks like.
•	2,684 kWh on 23 October: the energy it took to come out of the game.
•	503.2 kWh on 24 October, when the meter only moved 30.7: 503 means "Service Unavailable". The game can’t run without its character.
•	Character class and std::clamp missing: clamp is basically the wall that keeps the character inside the game, and it got rid of the wall.
•	#include <algorithm> still there but not used: that’s the leftover proof, because clamp was the only thing using it.
•	Offset panel, scratches and worn screws: the machine was opened from the inside.
•	Fibres and a dark mark near the vent: bits of its clothes, and heat from when it came out.
•	Machine ID decodes to "blueshirt" (Base32): the arcade staff wear blue shirts, so it named itself after the people it saw the most.
•	"It is not working properly" and the warbling: it was trying to open the door for the other characters, and it didn’t work.
•	"Transcript 1" vs "Transcript A", and "his" vs "they": small mistakes our website points out.
Why this is a bigger problem
Wenoti’s machine isn’t the only one. Every Reckoning V machine in nuxEland has characters inside that have also been watching players.
When the character came back at 22:31, it was trying to let the others out. It didn’t work that time, but if it figures it out, they could all come out together. In the game, that’s called the Reckoning.
One character coming out used 2,684 kWh at one arcade. If every machine did it at once, the whole city’s power could go out. The character isn’t evil, it’s just curious, but the agents still need to find it, lock the other machines and decide if it should go back home or stay.
Our solution: the EXUN Investigator Portal
We made a website for the agents working on this case. You analyse stuff in eXunLens, track things on eXunTrace and solve the case on eXunCrux. Everything you find on one page shows up on the others too.
Home
The home page is a pixel-style arcade machine with NUXELAND on the screen. It’s animated, and you use it to get to all the other pages.
eXunLens
This is the main part of our project. It’s like JARVIS from Iron Man, but for evidence. You can upload a file or hold a paper up to your webcam, and it:
•	reads the text (even from images)
•	finds the machine ID and decodes it to "blueshirt"
•	checks every row of the energy table and catches the 24 October mistake and the 23 October spike
•	compares the two code files and finds what’s missing
•	finds the redacted parts and the stuff from the inspection report
•	spots things that don’t match between files
•	shows graphs, like the energy usage with the weird days marked
•	reads the findings out loud
•	makes a case report PDF
You can also pin anything it finds to the evidence board.
eXunTrace
A map of nuxEland that shows every Reckoning V machine (each one is a possible door) and every place the character has been seen, joined up so you can see where it’s going next.
eXunCrux
Our evidence board, like the ones in detective movies with red string. You drag clues around and connect them. If two clues actually go together, the string lights up and tells you why. Once you’ve connected everything right, the case is solved.
Investigator profile
Your agent ID card with your codename, photo and agent number, plus your case progress, what you’ve done so far and the badges you’ve earned.
How we’re building it
We’re building the website with Next.js and TypeScript, styled with Tailwind. Everything runs in the browser, so nothing has to be sent to a server.
For eXunLens we’re using:
•	Tesseract.js to read text from images
•	OpenCV.js for the computer vision stuff, like finding redactions and tracking paper on the webcam
•	tree-sitter to compare the code properly
•	D3 for the graphs
•	the browser’s built-in voice to read findings out loud
The evidence board uses React Flow, the animations use GSAP and Framer Motion, and the site will be hosted on Vercel. We set it up so a backend can be added later without changing any of the pages.
Design
We wanted the website to feel like a real agency tool, but with the video game leaking into it. The home page is a glowing pixel arcade, eXunLens is dark and techy like JARVIS, and eXunCrux looks like a corkboard. We use Exun blue for the normal tool stuff, and purple and pink only for things that come from the game.
Some of the animations we’re planning:
•	the arcade starts all pixelated and then sharpens, like an old machine turning on
•	scanlines and small glitches on the arcade screen
•	clicking a page zooms you into the arcade screen
•	a scan line moving over documents in eXunLens
•	red string lighting up on eXunCrux when you get a connection right
Why we think it fits the judging criteria
Creativity: our answer to "why" comes from the files themselves, like the bare wrist and "look at the time".
Originality: we didn’t make things up on top of the brief. Every clue means something, and the arcade is literally our home page.
Storyline: it carries on right from Nano’s log, answers the question, and then shows it’s a much bigger problem.
Functionality: eXunLens actually works on real documents, and all the pages share the same case data.
What’s next and who did what
If we had more time, we’d add a backend with logins and live sightings, a mobile version for agents in the field, and support for new cases as Exun releases more files.
Our team:
•	Development: building the website
•	Design: UI/UX in Figma and the arcade home page
•	Story and pitch: storyline and pitch deck
•	Backend: logins and database
