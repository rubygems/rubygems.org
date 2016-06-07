$(function () {
    var suggester = new Bloodhound({
        datumTokenizer: Bloodhound.tokenizers.obj.whitespace('value'),
        queryTokenizer: Bloodhound.tokenizers.whitespace,
        remote: {
            url: '/search/autocomplete.json?query=%QUERY',
            wildcard: '%QUERY'
        }
    });

    $('#home_query, .header__search').typeahead({
        minLength: 2,
        highlight: true
    }, {
        name: "home_query",
        source: suggester
    });
});