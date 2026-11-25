<x-layout>
    <div class="uk-card uk-card-default uk-card-body">
        <h1 class="uk-card-title"><span uk-icon="check"></span> {{ config('app.name') }}</h1>
        <p>Laravel {{ app()->version() }}, PHP {{ PHP_VERSION }}</p>
    </div>
</x-layout>
