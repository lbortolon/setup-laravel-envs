<?php

it('shows the home page', function () {
    visit('/')
        ->assertSee('Laravel')
        ->assertNoJavaScriptErrors();
});
