import Foundation

struct StickerAsset: Identifiable, Codable, Hashable {
    let id: String
    let imageName: String
    let packId: String
}

struct StickerPack: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let previewImageName: String
    let stickers: [StickerAsset]
    let price: Decimal?
    let isSecret: Bool

    var isFree: Bool { price == nil }

    // Built-in free stickers
    static let freePack = StickerPack(
        id: "stickers.free",
        name: "Starter Pack",
        previewImageName: "pack_free_preview",
        stickers: [
            StickerAsset(id: "sticker.free.star", imageName: "sticker_star", packId: "stickers.free"),
            StickerAsset(id: "sticker.free.heart", imageName: "sticker_heart", packId: "stickers.free"),
            StickerAsset(id: "sticker.free.sparkle", imageName: "sticker_sparkle", packId: "stickers.free"),
            StickerAsset(id: "sticker.free.crown", imageName: "sticker_crown", packId: "stickers.free"),
        ],
        price: nil,
        isSecret: false
    )

    // Premium packs
    static let premiumPacks: [StickerPack] = [
        StickerPack(
            id: "stickers.fancy",
            name: "Fancy Pants",
            previewImageName: "pack_fancy_preview",
            stickers: [
                StickerAsset(id: "sticker.fancy.tophat", imageName: "sticker_tophat", packId: "stickers.fancy"),
                StickerAsset(id: "sticker.fancy.monocle", imageName: "sticker_monocle", packId: "stickers.fancy"),
                StickerAsset(id: "sticker.fancy.bowtie", imageName: "sticker_bowtie", packId: "stickers.fancy"),
                StickerAsset(id: "sticker.fancy.mustache", imageName: "sticker_mustache", packId: "stickers.fancy"),
                StickerAsset(id: "sticker.fancy.cane", imageName: "sticker_cane", packId: "stickers.fancy"),
            ],
            price: 0.99,
            isSecret: false
        ),
        StickerPack(
            id: "stickers.food",
            name: "Food Fight",
            previewImageName: "pack_food_preview",
            stickers: [
                StickerAsset(id: "sticker.food.pizza", imageName: "sticker_pizza", packId: "stickers.food"),
                StickerAsset(id: "sticker.food.taco", imageName: "sticker_taco", packId: "stickers.food"),
                StickerAsset(id: "sticker.food.donut", imageName: "sticker_donut", packId: "stickers.food"),
                StickerAsset(id: "sticker.food.hotdog", imageName: "sticker_hotdog", packId: "stickers.food"),
                StickerAsset(id: "sticker.food.icecream", imageName: "sticker_icecream", packId: "stickers.food"),
            ],
            price: 0.99,
            isSecret: false
        ),
    ]

    // Secret packs
    static let secretPacks: [StickerPack] = [
        StickerPack(
            id: "secret.stickers.rare",
            name: "Rare Finds",
            previewImageName: "pack_rare_preview",
            stickers: [
                StickerAsset(id: "sticker.rare.diamond", imageName: "sticker_diamond", packId: "secret.stickers.rare"),
                StickerAsset(id: "sticker.rare.rainbow", imageName: "sticker_rainbow", packId: "secret.stickers.rare"),
                StickerAsset(id: "sticker.rare.fire", imageName: "sticker_fire", packId: "secret.stickers.rare"),
            ],
            price: nil,
            isSecret: true
        ),
    ]

    static var all: [StickerPack] {
        [freePack] + premiumPacks + secretPacks
    }
}
