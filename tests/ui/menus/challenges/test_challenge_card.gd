## © [2026] A7 Studio. All rights reserved. Trademark.
##
## [ChallengeCard]: a failed challenge switches the three labels to their failed variations, otherwise the difficulty label takes the variation of its difficulty.
extends GdUnitTestSuite

const CARD_SCENE: PackedScene = preload("res://ui/menus/challenges/challenge_card.tscn")


func test_a_failed_challenge_turns_every_label_to_the_failed_variations() -> void:
	var card: ChallengeCard = _card("Hard", true)

	assert_str(card.title_label.theme_type_variation).is_equal(&"CardTitleFailed")
	assert_str(card.desc_label.theme_type_variation).is_equal(&"CardTextFailed")
	assert_str(card.diff_label.theme_type_variation).is_equal(&"CardTextFailed")
	assert_str(card.diff_label.text).is_equal(tr("CHALLENGE.STATUS.FAILED"))


func test_every_difficulty_has_its_own_variation() -> void:
	for difficulty: String in ChallengeCard.DIFFICULTY_VARIATIONS:
		var card: ChallengeCard = _card(difficulty, false)

		assert_str(card.title_label.theme_type_variation).is_equal(&"CardTitle")
		assert_str(card.desc_label.theme_type_variation).is_equal(&"CardText")
		assert_str(card.diff_label.theme_type_variation).is_equal(ChallengeCard.DIFFICULTY_VARIATIONS[difficulty])


func test_an_unknown_difficulty_falls_back_to_the_plain_card_text() -> void:
	var card: ChallengeCard = _card("Nightmare", false)

	assert_str(card.diff_label.theme_type_variation).is_equal(&"CardText")


func test_a_challenge_that_fails_later_switches_the_variations() -> void:
	var card: ChallengeCard = _card("Easy", false)

	card._on_challenge_status_updated("cha.test", false, true)

	assert_str(card.title_label.theme_type_variation).is_equal(&"CardTitleFailed")
	assert_str(card.diff_label.theme_type_variation).is_equal(&"CardTextFailed")


func _card(difficulty: String, failed: bool) -> ChallengeCard:
	var challenge: Challenge = auto_free(Challenge.new("cha.test", "CHALLENGE.TITLE", "CHALLENGE.DESC", difficulty))
	challenge.is_failed = failed
	var card: ChallengeCard = auto_free(CARD_SCENE.instantiate())
	add_child(card)
	card.setup(challenge, false)
	return card
