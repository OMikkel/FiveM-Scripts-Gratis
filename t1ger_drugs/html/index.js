function closeMain() {
	$(".container").css("display", "none");
}
function openMain() {
	$(".container").css("display", "block");
}


// Listen for NUI Events
window.addEventListener('message', function (event) {

	var item = event.data;

	// Open & Close main window
	if (item.status == "show") {
            $("#h11").text(item.cokename + " | $" + item.coke)

            $("#h12").text(item.methname + " | $" + item.meth)

            $("#h13").text(item.weedname + " | $" + item.weed)

        openMain();
	}

	if (item.status == "hide") {
		closeMain();
    }
    
    if (item.status == "add"){

	}
});

$(".cancel").click(function(){
    $.post('http://t1ger_drugs/exit', JSON.stringify({}));
});

$(".button1").click(function(){
    $.post('http://t1ger_drugs/drugs1', JSON.stringify({
        item: "Coke",
        price: 7500
    }));
});
$(".button2").click(function(){
    $.post('http://t1ger_drugs/drugs2', JSON.stringify({
        item: "Meth",
        price: 6000
    }));
});
$(".button3").click(function(){
    $.post('http://t1ger_drugs/drugs3', JSON.stringify({
        item: "Weed",
        price: 3500
    }));
});


