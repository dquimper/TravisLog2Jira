$(document).ready ->
  $(".issue form").on("ajax:success", (e, data, status, xhr) ->
    console.log "success"
    $(e.currentTarget).parents(".issue").slideUp("slow")
  ).on "ajax:error", (e, xhr, status, error) ->
    alert("ERROR")
