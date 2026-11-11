import Foundation

func germanContent(dates: [Date]) -> DemoContent {
    let home = Tag(id: UUID(uuidString: "6F1A0002-0000-4000-8000-000000000001")!, name: "Zuhause", style: .emoji("🏠"))
    let travel = Tag(id: UUID(uuidString: "6F1A0002-0000-4000-8000-000000000002")!, name: "Reisen", style: .emoji("✈️"))
    let work = Tag(id: UUID(uuidString: "6F1A0002-0000-4000-8000-000000000003")!, name: "Arbeit", style: .emoji("💼"))
    let shopping = Tag(id: UUID(uuidString: "6F1A0002-0000-4000-8000-000000000004")!, name: "Einkaufen", style: .emoji("🛒"))
    let ideas = Tag(id: UUID(uuidString: "6F1A0002-0000-4000-8000-000000000005")!, name: "Ideen", style: .emoji("💡"))
    let birthdays = Tag(id: UUID(uuidString: "6F1A0002-0000-4000-8000-000000000006")!, name: "Geburtstage", style: .emoji("🎂"))
    let reading = Tag(id: UUID(uuidString: "6F1A0002-0000-4000-8000-000000000007")!, name: "Lesen", style: .color("#0088FF"))

    let cal = Calendar.current
    let inTwoDays = cal.date(byAdding: .day, value: 2, to: dates[0])
    let tomorrow = cal.date(byAdding: .day, value: 1, to: dates[0])
    let inAWeek = cal.date(byAdding: .day, value: 7, to: dates[0])

    return DemoContent(
        tags: [home, travel, work, shopping, ideas, birthdays, reading],
        days: [
            DemoDay(slot: 0, blocks: [
                note("Wohnungsbesichtigung Donnerstag 18 Uhr – nach dem Balkon fragen", [home.id]),
                note("Wochenende an der Ostsee? Züge für Freitagabend checken"),
                note("Hafermilch, Kaffee, Zitronen, Basilikum", [shopping.id]),
                note("Idee fürs Team: eine wöchentliche Zusammenfassung per Mail", [work.id, ideas.id]),
                note("Podcast-Tipp von Sam: die Folge über Schlaf"),
            ]),
            DemoDay(slot: 1, blocks: [
                todo("Zug an die Ostsee buchen", done: true, id: "de-1", due: dates[1], tags: [travel.id]),
                todo("Ladekabel und Badesachen einpacken", done: false, id: "de-2", due: inTwoDays, tags: [travel.id]),
                todo("Noor fragen, ob sie die Pflanzen gießt", done: false, id: "de-3", due: tomorrow, tags: [home.id]),
                todo("Geschenk für Lena kaufen", done: true, id: "de-4", due: inAWeek, tags: [birthdays.id]),
            ]),
            DemoDay(slot: 2, blocks: [
                note("Lenas Geburtstag am 22. – sie wünscht sich einen Töpferkurs", [birthdays.id]),
                note("Buch für den Lesekreis bis Sonntag fertig lesen", [reading.id]),
            ]),
            DemoDay(slot: 3, blocks: [
                note("Retro: montags weniger Meetings, mehr Fokuszeit", [work.id]),
                note("Rezept: Zitronenpasta mit Basilikum und Parmesan"),
            ]),
            DemoDay(slot: 4, blocks: [
                note("Vermieter Fotos vom Küchenhahn schicken", [home.id]),
                todo("Zahnarzt anrufen", done: false, id: "de-5", due: inTwoDays),
            ]),
            DemoDay(slot: 5, blocks: [
                note("App-Idee: Gießerinnerungen für Pflanzen mit Fotos", [ideas.id]),
            ]),
            DemoDay(slot: 6, blocks: [
                note("Neue Laufrunde am Fluss entlang – etwa 5 km"),
            ]),
            DemoDay(slot: 7, blocks: [
                note("Umzugskartons: im Supermarkt nachfragen", [home.id, shopping.id]),
            ]),
        ]
    )
}
