fletching_table = {}
--mostly from mcl_crafting_table
local S = minetest.get_translator(minetest.get_current_modname())
local F = minetest.formspec_escape
local C = minetest.colorize

--extend show_formspec to check the label of the formspec
--mark the meta on the player based on what they just opened
local old_show_formspec = minetest.show_formspec
local show_formspec = function(playername, formname, formspec)
	local player = minetest.get_player_by_name(playername)
	local meta = player:get_meta()
	--todo use the formspec methods to get the label out if possible
	if string.match(formspec, "Fletching")then
		meta:set_string("crafting_table", "fletching")
	else
		meta:set_string("crafting_table", "crafting")
	end
	old_show_formspec(playername, formname, formspec)
end
minetest.show_formspec = show_formspec

--the base crafting_table must use the extended function too
function mcl_crafting_table.show_crafting_form(player)
	local inv = player:get_inventory()
	if inv then
		inv:set_width("craft", 3)
		inv:set_size("craft", 9)
	end
	show_formspec(player:get_player_name(), "main", mcl_crafting_table.formspec)
end

fletching_table.formspec = table.concat({
	"formspec_version[4]",
	"size[11.75,10.425]",
	--this label is the only alteration
	"label[2.25,0.375;" .. F(C(mcl_formspec.label_color, S("Fletching"))) .. "]",

	mcl_formspec.get_itemslot_bg_v4(2.25, 0.75, 3, 3),
	"list[current_player;craft;2.25,0.75;3,3;]",

	"image[6.125,2;1.5,1;gui_crafting_arrow.png]",

	mcl_formspec.get_itemslot_bg_v4(8.2, 2, 1, 1, 0.2),
	"list[current_player;craftpreview;8.2,2;1,1;]",

	"label[0.375,4.7;" .. F(C(mcl_formspec.label_color, S("Inventory"))) .. "]",

	mcl_formspec.get_itemslot_bg_v4(0.375, 5.1, 9, 3),
	"list[current_player;main;0.375,5.1;9,3;9]",

	mcl_formspec.get_itemslot_bg_v4(0.375, 9.05, 9, 1),
	"list[current_player;main;0.375,9.05;9,1;]",

	"listring[current_player;craft]",
	"listring[current_player;main]",

	--Crafting guide button
	"image_button[0.325,1.95;1.1,1.1;craftguide_book.png;__mcl_craftguide;]",
	"tooltip[__mcl_craftguide;" .. F(S("Recipe book")) .. "]",
})

--also from mcl_crafting_table
function fletching_table.show_crafting_form(player)
	local inv = player:get_inventory()
	if inv then
		inv:set_width("craft", 3)
		inv:set_size("craft", 9)
	end
	show_formspec(player:get_player_name(), "main", fletching_table.formspec)
end

--override the native fletching_table to show the modified formspec
minetest.override_item("mcl_fletching_table:fletching_table", {
	on_rightclick = function(pos, node, player, itemstack)
		if not player:get_player_control().sneak then
			fletching_table.show_crafting_form(player)
		end
	end,
})

--a little helper function
local function tableContains(table, str)
	for _, s in pairs(table) do
		if s == str then return true end
	end
	return false
end
		
--register craft_predict
--read the meta and determine if the last table was a fletching or crafting table
--also double check the length of the grid to see if it's the inventory 2x2
--if it's a fletching recipe (in the list) on a fletching_table, allow it,
--otherwise disallow; also do the reverse on a regular crafting_table
minetest.register_craft_predict(function(itemstack, player, old_craft_grid, craft_inv)
    local meta = player:get_meta()
    local table = meta:get_string("crafting_table")
	local fletching = {"mcl_bows:arrow"}
    if table == "fletching" then --it could be the regular 2x2
		if #old_craft_grid == 4 then
			table = "crafting"
		end
    end
	--verbose and clear
	if table == "fletching" then
		if tableContains(fletching, itemstack:get_name()) then
			return nil
		else
			return ItemStack("")
		end
	else
		if tableContains(fletching, itemstack:get_name()) then
			return ItemStack("")
		else
			return nil
		end
	end
end)