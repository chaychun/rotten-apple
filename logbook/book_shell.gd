extends Control

enum Tab { POKEDEX, QUEST }

const BOOK_MAX_SIDE := 1700.0

@onready var _book_frame: Control = $BookFrame
@onready var _prev: Button = $BookFrame/BottomBar/Prev
@onready var _next: Button = $BookFrame/BottomBar/Next
@onready var _tab_pokedex: Button = $BookFrame/Bookmarks/TabPokedex
@onready var _tab_quest: Button = $BookFrame/Bookmarks/TabQuest
@onready var _postit_pokedex: TextureRect = $BookFrame/Bookmarks/PostitClip/PostitPokedex
@onready var _postit_quest: TextureRect = $BookFrame/Bookmarks/PostitClip/PostitQuest
@onready var _letter_pokedex: Label = $BookFrame/Bookmarks/LetterPokedex
@onready var _letter_quest: Label = $BookFrame/Bookmarks/LetterQuest

const _LETTER_ACTIVE := Color(1, 1, 1, 1)
const _LETTER_INACTIVE := Color(1, 1, 1, 0.5)
@onready var _pokedex_page: BookPage = $BookFrame/Content/PokedexPage
@onready var _quest_page: BookPage = $BookFrame/Content/QuestPage

var _active_tab := Tab.QUEST


func _ready() -> void:
	_prev.pressed.connect(_on_prev)
	_next.pressed.connect(_on_next)
	_tab_pokedex.pressed.connect(_select_tab.bind(Tab.POKEDEX))
	_tab_quest.pressed.connect(_select_tab.bind(Tab.QUEST))
	_pokedex_page.contents_changed.connect(_on_contents_changed.bind(_pokedex_page))
	_quest_page.contents_changed.connect(_on_contents_changed.bind(_quest_page))
	get_viewport().size_changed.connect(_fit_book)
	_fit_book()
	_apply_tab()


# Called by LogbookLayer.open() so the active page refreshes after being closed.
func on_open() -> void:
	_apply_tab()


func _select_tab(tab: int) -> void:
	_active_tab = tab
	_apply_tab()


func _apply_tab() -> void:
	_pokedex_page.visible = _active_tab == Tab.POKEDEX
	_quest_page.visible = _active_tab == Tab.QUEST

	_postit_pokedex.visible = _active_tab != Tab.POKEDEX
	_postit_quest.visible = _active_tab != Tab.QUEST

	_letter_pokedex.modulate = _LETTER_ACTIVE if _active_tab == Tab.POKEDEX else _LETTER_INACTIVE
	_letter_quest.modulate = _LETTER_ACTIVE if _active_tab == Tab.QUEST else _LETTER_INACTIVE
	var page := _active_page()
	page.on_show()
	_set_nav_enabled(not page.is_empty())


func _active_page() -> BookPage:
	return _quest_page if _active_tab == Tab.QUEST else _pokedex_page


func _on_contents_changed(page: BookPage) -> void:
	if page == _active_page():
		_set_nav_enabled(not page.is_empty())


func _set_nav_enabled(enabled: bool) -> void:
	_prev.disabled = not enabled
	_next.disabled = not enabled


func _on_prev() -> void:
	_active_page().go_prev()


func _on_next() -> void:
	_active_page().go_next()


# Book image is square; keep the frame square so fraction-anchored children
# stay aligned to the painted art at any size.
func _fit_book() -> void:
	var vp := get_viewport_rect().size
	var side: float = min(vp.x, vp.y * 1.5, BOOK_MAX_SIDE)
	_book_frame.offset_left = -side * 0.5
	_book_frame.offset_top = -side * 0.5
	_book_frame.offset_right = side * 0.5
	_book_frame.offset_bottom = side * 0.5
