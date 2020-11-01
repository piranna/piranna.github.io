---
layout: post
title: Updates on the freelancer calculator
twitter: '1248936943431364608'
---

I've been working lately a bit more on the
[freelancer calculator](2020-03-30-Freelancer-calculator.md), and was able to
identify and fix some of its errors.

Main important one was not properly using the inverse of the fractions, like
increasing a number by a third, and later decreasing the result also by a third
instead of a quart to get the original number (`a + a/3 = b` -> `4a/3 = b` ->
`4a = 3b` -> `a = 3b/4` -> `a = 0.75b`).

So, having this fixed, numbers conversions match better both from employee to
freelancer and viceversa. They don't really fully match, but differences are in
the order of 0.1%, so seems they are due to rounding errors. What's more
annoying is that this calcs confirm my concerns about having asking for such
high rates when using a `1:150` relationship between freelance daily rate and
anual gross salary (as already said, the usual value used in Spain to negotiate
the salary as employee, instead of net salary as it's common practice in other
countries), resulting in a relationship of about `1:200` for same costs to the
client company, or a higher relationship if we take same net salary as
reference, being as high as `1:300` with the bare minimum costs. That's a huge
difference, so I've tried to close the gap by adding some not-so-superfluous
costs that could be covered by companies for an equal position as employee and a
freelance needs to pay by himself, like mortages, civil responsabilities,
co-working space, laptop (some USA or Japan companies gift the work laptop to
their employees and provides them a newer one each year), internet access,
public transport card, daily meals, or also gym membership pass. After all these
monthly fixed freelance costs (more than 1300€ in total...) that includes a
self-assigned social beneficts VIP package, the relationship is still as high as
`1:260`.

This shows that due to Spain per-employee taxes, in all cases working as
freelancer cost less to the companies than contracting an employee for the same
position by a huge margin (up to a 20%), and at the same time can provide more
net salary to the worker. This could lead to think that's better to work as
freelancer instead of employee and administer yourself your own costs, but I'm
not advocating for that since these calcs are done in the ideal case of working
full-time in long-term projects in both cases (that's not the usual for
freelance contracts), and the increased margins are at expenses of unemployment
and retirement mortages and other social beneficts (both provided by goberment
taxes or by companies themselves). Instead, this calculator shows how much is a
safe range to ask for as a freelance, since for a worker with the same net
salary a company could be saving up to a 20% of costs than contracting an
employee, so don't be afraid of asking for high bucks, and in the case of a
freelancer not working at the same time as employee, it shows that he should pay
a higher freelance quota (in Spain, currently you decide your own social
security compensation and 80% of freelancers pay the minimum exigible by law due
to the small ROI we usually get for it, and so this calculator use that number),
pay for a retirement mortage... or more probably, do both things.
