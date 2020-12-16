// Lavet af: OMikkel#3217
// Script: omik_attachments

$(document).ready( function () {
    window.addEventListener("message", function(event) {
        var item = event.data;
        
        if (item.status == "OpenMenu") {
            $(".container").css("display", "block");
        }else if (item.status == "CloseMenu") {
            $(".container").css("display", "none");
        }

        if (item.action == "AddAttachments") {
            $("#attachments").empty();
            $("#weapon_name").text(item.info[0]);
            $("#weapon_image").attr("src",item.info[1]);
            item.table.forEach(AddAttachmentCard)
        }

    });
});
$(document).on('click', '#equip', function() {
	var $button = $(this);
	var $name = $button.attr("name")
    $.post("http://omik_attachments/AttachExtra", JSON.stringify({
        attachment: $name
    }));
}) ;

document.onkeyup = function (data) {
    if (data.which == 27) {
        $.post("http://omik_attachments/CloseMenu", JSON.stringify({}));
        return
    }
};

function AddAttachmentCard(item, index) {
    console.log(item, index)
    $( "#attachments" ).append('<div class="attachment-card">' +
        '<div id="container">' +
            '<h4><b>' + item[0] + '</b></h4> ' +
            '<div class="equip">' +
                '<div id="equip" name="' + item[1] + '">Equip</div>' +
            '</div>' +
        '</div>' +
    '</div>');
}