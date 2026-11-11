import Foundation

func englishContent(dates: [Date]) -> DemoContent {
    let home = Tag(id: UUID(uuidString: "6F1A0001-0000-4000-8000-000000000001")!, name: "Home", style: .emoji("🏠"))
    let travel = Tag(id: UUID(uuidString: "6F1A0001-0000-4000-8000-000000000002")!, name: "Travel", style: .emoji("✈️"))
    let work = Tag(id: UUID(uuidString: "6F1A0001-0000-4000-8000-000000000003")!, name: "Work", style: .emoji("💼"))
    let shopping = Tag(id: UUID(uuidString: "6F1A0001-0000-4000-8000-000000000004")!, name: "Shopping", style: .emoji("🛒"))
    let ideas = Tag(id: UUID(uuidString: "6F1A0001-0000-4000-8000-000000000005")!, name: "Ideas", style: .emoji("💡"))
    let birthdays = Tag(id: UUID(uuidString: "6F1A0001-0000-4000-8000-000000000006")!, name: "Birthdays", style: .emoji("🎂"))
    let reading = Tag(id: UUID(uuidString: "6F1A0001-0000-4000-8000-000000000007")!, name: "Reading", style: .color("#0088FF"))

    let cal = Calendar.current
    let inTwoDays = cal.date(byAdding: .day, value: 2, to: dates[0])
    let tomorrow = cal.date(byAdding: .day, value: 1, to: dates[0])
    let inAWeek = cal.date(byAdding: .day, value: 7, to: dates[0])

    return DemoContent(
        tags: [home, travel, work, shopping, ideas, birthdays, reading],
        days: [
            DemoDay(slot: 0, blocks: [
                note("Flat viewing Thursday 6 pm — ask about the balcony", [home.id]),
                note("Weekend at the coast? Check trains for Friday evening"),
                note("Oat milk, coffee, lemons, basil", [shopping.id]),
                note("Pitch idea: a weekly summary email for the team", [work.id, ideas.id]),
                note("Podcast tip from Sam: the episode about sleep"),
            ]),
            DemoDay(slot: 1, blocks: [
                todo("Book train to the coast", done: true, id: "en-1", due: dates[1], tags: [travel.id]),
                todo("Pack charger and swimsuit", done: false, id: "en-2", due: inTwoDays, tags: [travel.id]),
                todo("Ask Noor to water the plants", done: false, id: "en-3", due: tomorrow, tags: [home.id]),
                todo("Buy a gift for Lena", done: true, id: "en-4", due: inAWeek, tags: [birthdays.id]),
            ]),
            DemoDay(slot: 2, blocks: [
                note("Lena's birthday on the 22nd — she'd love a pottery class", [birthdays.id]),
                note("Finish the book club novel by Sunday", [reading.id]),
            ]),
            DemoDay(slot: 3, blocks: [
                note("Retro: fewer meetings on Mondays, more focus time", [work.id]),
                note("Recipe: lemon pasta with basil and parmesan"),
            ]),
            DemoDay(slot: 4, blocks: [
                note("Send the landlord photos of the kitchen tap", [home.id]),
                todo("Call the dentist", done: false, id: "en-5", due: inTwoDays),
            ]),
            DemoDay(slot: 5, blocks: [
                note("App idea: plant-watering reminders with photos", [ideas.id]),
            ]),
            DemoDay(slot: 6, blocks: [
                note("New running route along the river — about 5 km"),
            ]),
            DemoDay(slot: 7, blocks: [
                note("Moving boxes: ask at the supermarket", [home.id, shopping.id]),
            ]),
        ]
    )
}
