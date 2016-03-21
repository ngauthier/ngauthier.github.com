---
layout: post
title: Interview Notes
date: 2016-03-21
---

I was asked recently to write up how I give interviews, and I realized that it could be very helpful to publish these publicly. As you will understand while reading, knowledge of my interview and its rubrick doesn't give a potential candidate an edge. In fact, I think it would lead to a more accurate interview. Enjoy, and share your thoughts!

## General Format

### Part 1: Chat

30 minutes talking. We would talk about previous experience, current interests, what it's like at the company they are interviewing for. No formal questions like "what vegetable are you?" only casual things. The goal of this phase is to establish our relationship and communication style so that we can speak easily when we get to the technical part. Candidates could be disqualified during this phase, though.

Examples of negative experiences and qualities:

1. Superiority complex / elitism / asshole: "well, actually", patronizing me, talking poorly of past experiences or coworkers, bragging and gloating without specific examples (i.e. "I'm pretty much the best developer I've ever known" is bad but "I've done some really incredible things with postgresql on past projects" is good).
1. Inability to explain: if I ask about a past project or a language or anything, and the candidate can't tell me about it at all, or explains very tersely and stops.
1. Lack of interest: it's odd but sometimes you get someone who just doesn't seem to even care about the interview or working for the company or anything.

Examples of positive experiences and qualities:

1. If I ask about something pretty simple, like "What did you work on at X corp" and they explode into enthusiasm and talk about it on their own with only minimal "ah", "ok", "cool!" from me for a while. This person really loves what they do.
1. Mutual feeling of at-ease when we speak. We're having an honest conversation, there's no positioning, choosing words carefully. We are just talking about stuff and establish a connection quickly. It can take until the end of the 30 minutes for this, but that's ok. As an interviewer, you should set the example of speaking honestly and openly.
1. Opinions and willingness to share them. Doesn't really matter if we agree or not, but I want to hear that the candidate has their own opinions on relevant subjects and is excited to discuss them.

### Part 2: Code

One hour of coding. I've done two projects during this part since 2009. At first, it was always "build a rails blog" since I was only interviewing for Rails (although I had someone do it in Django because that's what they knew, and they got the job!). Later on, it became "work with some json" because it was more of a general position but web background was part of it.

Here is how the JSON project would go:

1. I give them some JSON data. I would use some Codeship API data. It had a root object, and one of the values was an array with some computable properties.
1. I would ask them to give me one of the top level key's values. At this point the person says "um, how do you want me to code that?" and I will say "you could do a script, or a binary, or a library, it all works for me!". At this point I also mention that "there are no rules" for this interview.
1. "OK, before we do the next thing, anything you want to clean up?"
1. I ask for the number of items in the array value of the object (just count)
1. "OK, anything you want to clean up or refactor here?"
1. I ask to compute something on the array values (percentage where some bool is true, for example)
1. refactor again
1. I ask to compute something else, but more complicated (often this one is avg(timestamp-timestamp) to get average duration of an event).
1. refactor again

That usually takes the hour. If not, I will have a couple of harder and harder questions. The point is not how far we get, but how we do it.

At this point, you're probably thinking "wow that is really easy, how is this effective?". On the one hand, I am evaluating their ability to do the assignment. I have passed candidates who only were able to do the first task. But usually it's because the language they were comfortable with had poor json support so we spent the whole time figuring that out. But that's OK! That's totally something programmers do all the time, and your ability to do that well is just as important as slamming out easy code.

Here is what I am really looking for when we do this part of the interview:

1. How is working with this person? I am acting as a "novice pair" so I don't really know how to do a lot of stuff, but I'm still contributing a little bit. Do I enjoy coding with this person? Would I ask them to pair with me if I was stuck?
1. What is their attention to detail? How often did they miss little things or leave loose ends lying around? Are they rushing sloppily to get through as much as possible in the interview, or are they really trying to get it right? (Spoiler alert: this is how they will attack projects when they're on the job too!)
1. Where is their balance point between productivity and perfection? More specifically, how much do they refactor when prompted? I have had people who just say "It's great the way it is I wouldn't change it" when there are obvious duplications. I've also had people who went full rabbit-hole on something really unimportant. I try to figure out their balance point. Generally, I will take people who are perfectionists, and in the middle, but not those who don't see the possibility of improvement. (Spoiler alert: they are often "expert beginners" and they will not improve themselves while on the job. Why should they? They're already perfect and they write perfect code the first time).
1. Do they ask for help? I really try to act like a pair, and hopefully from the chat section we are at ease. When they don't receive enough clarification when I tell them the next part of the project, do they ask for clarification, or do they guess what I want? When they get stuck, will they ask me for help? It's extremely important that the candidate ask for help during the exercise. *Especially* if they are more senior. I want to work on a team of people who get the most out of each other to do their best work. I have even had candidates ask me directly for the solution to one of my questions. This is actually a huge point in their favor! I will then politely say that while I do know the answer unfortunately this is an interview and they will need to solve it themselves, but I will usually give them a tip.
1. Comfort with their tools. I always have the interviewee work in their most comfortable and familiar environment. The language of their choice, the editor of their choice. Always on a computer they brought with them. They should be quick at the keyboard, quick on their editor, quick on the browser searching for help, quick to evaluate which stack overflow post is the most relevant, etc. If you were hiring a carpenter and they struggled with hitting a nail, they don't hit a lot of nails. Many interviews try to throw a fastball and see if the interviewee can hit it. I set up a T-ball and see how far they can hit.

Boiling it down, these are the qualities I am evaluating:

1. Communication ability: honesty, frankness, and ease.
1. Attention to detail, not sloppy, no "messy room syndrome"
1. Always looking for improvement. Never satisfied. Understanding that perfection is both unnattainable but worth attempting.
1. Open to assistance from anyone, not afraid to ask for help, open to the thoughts and opinions of others.
1. Programming is a natural skill for them. They are quick and comfortable and experienced with what they claim as their experience level.

## Conclusion

You may have noticed that the actual act of programming is a minority in the qualities I am assessing. That is because I truly believe it is a minority in the qualities of a great team member. You will be spending the majority of your week interacting with the people on your team. Those interactions have to be smooth and productive for you to be able to even get to the programming part of your job. The easier it is to talk to your teammates, debate, come to conclusions, get help, and solve problems, the more time you will spend implementing your solutions. It will also significantly affect your happiness and burnout.

