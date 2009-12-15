# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run the gemspec command
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{talia_core}
  s.version = "0.4.8"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Danilo Giacomi", "Roberto Tofani", "Luca Guidi", "Michele Nucci", "Daniel Hahn"]
  s.date = %q{2009-12-15}
  s.default_executable = %q{talia}
  s.description = %q{This is the core plugin for building a digital library with Talia/Rails.}
  s.email = %q{ghub@limitedcreativity.org}
  s.executables = ["talia"]
  s.extra_rdoc_files = [
    "README.rdoc"
  ]
  s.files = [
    "VERSION.yml",
     "config/database.yml",
     "config/database.yml.example",
     "config/rdfstore.yml",
     "config/rdfstore.yml.example",
     "config/rdfstore.yml.rdflite_example",
     "config/rdfstore.yml.redland_example",
     "config/talia_core.yml",
     "config/talia_core.yml.example",
     "generators/generator_helpers.rb",
     "generators/talia_admin/USAGE",
     "generators/talia_admin/talia_admin_generator.rb",
     "generators/talia_admin/templates/controllers/admin/background_controller.rb",
     "generators/talia_admin/templates/controllers/admin/custom_templates_controller.rb",
     "generators/talia_admin/templates/controllers/admin/locales_controller.rb",
     "generators/talia_admin/templates/controllers/admin/roles_controller.rb",
     "generators/talia_admin/templates/controllers/admin/sources_controller.rb",
     "generators/talia_admin/templates/controllers/admin/translations_controller.rb",
     "generators/talia_admin/templates/controllers/admin/users_controller.rb",
     "generators/talia_admin/templates/controllers/admin_controller.rb",
     "generators/talia_admin/templates/helpers/admin/background_helper.rb",
     "generators/talia_admin/templates/helpers/admin/custom_templates_helper.rb",
     "generators/talia_admin/templates/helpers/admin/locales_helper.rb",
     "generators/talia_admin/templates/helpers/admin/roles_helper.rb",
     "generators/talia_admin/templates/helpers/admin/sources_helper.rb",
     "generators/talia_admin/templates/helpers/admin/translations_helper.rb",
     "generators/talia_admin/templates/helpers/admin/users_helper.rb",
     "generators/talia_admin/templates/helpers/admin_helper.rb",
     "generators/talia_admin/templates/migrations/populate_users.rb",
     "generators/talia_admin/templates/models/role.rb",
     "generators/talia_admin/templates/public/javascripts/backend.js",
     "generators/talia_admin/templates/public/javascripts/lowpro.js",
     "generators/talia_admin/templates/public/stylesheets/talia_core/backend.css",
     "generators/talia_admin/templates/public/stylesheets/talia_core/images/body_bg.gif",
     "generators/talia_admin/templates/public/stylesheets/talia_core/images/footer_bg.gif",
     "generators/talia_admin/templates/public/stylesheets/talia_core/images/header.jpg",
     "generators/talia_admin/templates/public/stylesheets/talia_core/images/header_bg.gif",
     "generators/talia_admin/templates/public/stylesheets/talia_core/images/menu.jpg",
     "generators/talia_admin/templates/public/stylesheets/talia_core/images/menu_bg.gif",
     "generators/talia_admin/templates/public/stylesheets/talia_core/images/opednid.gif",
     "generators/talia_admin/templates/public/stylesheets/talia_core/images/page_bg.jpg",
     "generators/talia_admin/templates/public/stylesheets/talia_core/images/triangolino.gif",
     "generators/talia_admin/templates/public/stylesheets/talia_core/images/triangolino_full.gif",
     "generators/talia_admin/templates/test/functional/admin/custom_templates_controller_test.rb",
     "generators/talia_admin/templates/test/functional/admin/locales_controller_test.rb",
     "generators/talia_admin/templates/test/functional/admin/sources_controller_test.rb",
     "generators/talia_admin/templates/test/functional/admin/translations_controller_test.rb",
     "generators/talia_admin/templates/test/functional/admin/users_controller_test.rb",
     "generators/talia_admin/templates/test/functional/admin_controller_test.rb",
     "generators/talia_admin/templates/views/admin/background/_finished.html.erb",
     "generators/talia_admin/templates/views/admin/background/_pending.html.erb",
     "generators/talia_admin/templates/views/admin/background/_progress.html.erb",
     "generators/talia_admin/templates/views/admin/background/_running.html.erb",
     "generators/talia_admin/templates/views/admin/background/environment.html.erb",
     "generators/talia_admin/templates/views/admin/background/show.html.erb",
     "generators/talia_admin/templates/views/admin/background/stderr.html.erb",
     "generators/talia_admin/templates/views/admin/background/stdin.html.erb",
     "generators/talia_admin/templates/views/admin/background/stdout.html.erb",
     "generators/talia_admin/templates/views/admin/custom_templates/_content_form_column.rhtml",
     "generators/talia_admin/templates/views/admin/custom_templates/_template_type_form_column.rhtml",
     "generators/talia_admin/templates/views/admin/index.html.erb",
     "generators/talia_admin/templates/views/admin/locales/new.html.erb",
     "generators/talia_admin/templates/views/admin/sources/_show.html.erb",
     "generators/talia_admin/templates/views/admin/translations/_new_translation.html.erb",
     "generators/talia_admin/templates/views/admin/translations/_translation.html.erb",
     "generators/talia_admin/templates/views/admin/translations/edit.html.erb",
     "generators/talia_admin/templates/views/layouts/admin.html.erb",
     "generators/talia_base/USAGE",
     "generators/talia_base/talia_base_generator.rb",
     "generators/talia_base/templates/README",
     "generators/talia_base/templates/app/controllers/custom_templates_controller.rb",
     "generators/talia_base/templates/app/controllers/ontologies_controller.rb",
     "generators/talia_base/templates/app/controllers/source_data_controller.rb",
     "generators/talia_base/templates/app/controllers/sources_controller.rb",
     "generators/talia_base/templates/app/controllers/types_controller.rb",
     "generators/talia_base/templates/app/helpers/custom_templates_helper.rb",
     "generators/talia_base/templates/app/helpers/ontologies_helper.rb",
     "generators/talia_base/templates/app/helpers/sessions_helper.rb",
     "generators/talia_base/templates/app/helpers/source_data_helper.rb",
     "generators/talia_base/templates/app/helpers/sources_helper.rb",
     "generators/talia_base/templates/app/helpers/types_helper.rb",
     "generators/talia_base/templates/app/views/layouts/sources.html.erb",
     "generators/talia_base/templates/app/views/ontologies/index.builder",
     "generators/talia_base/templates/app/views/ontologies/show.builder",
     "generators/talia_base/templates/app/views/source_data/show.html.erb",
     "generators/talia_base/templates/app/views/sources/_data_list.html.erb",
     "generators/talia_base/templates/app/views/sources/_form.html.erb",
     "generators/talia_base/templates/app/views/sources/_property_item.html.erb",
     "generators/talia_base/templates/app/views/sources/_property_list.html.erb",
     "generators/talia_base/templates/app/views/sources/edit.html.erb",
     "generators/talia_base/templates/app/views/sources/index.html.erb",
     "generators/talia_base/templates/app/views/sources/new.html.erb",
     "generators/talia_base/templates/app/views/sources/semantic_templates/default/default.html.erb",
     "generators/talia_base/templates/app/views/sources/show.html.erb",
     "generators/talia_base/templates/app/views/types/index.html.erb",
     "generators/talia_base/templates/app/views/types/show.html.erb",
     "generators/talia_base/templates/config/routes.rb",
     "generators/talia_base/templates/config/talia_initializer.rb",
     "generators/talia_base/templates/config/warble.rb",
     "generators/talia_base/templates/migrations/bj_migration.rb",
     "generators/talia_base/templates/migrations/constraint_migration.rb",
     "generators/talia_base/templates/migrations/create_active_sources.rb",
     "generators/talia_base/templates/migrations/create_custom_templates.rb",
     "generators/talia_base/templates/migrations/create_data_records.rb",
     "generators/talia_base/templates/migrations/create_progress_jobs.rb",
     "generators/talia_base/templates/migrations/create_semantic_properties.rb",
     "generators/talia_base/templates/migrations/create_semantic_relations.rb",
     "generators/talia_base/templates/migrations/create_workflows.rb",
     "generators/talia_base/templates/migrations/upgrade_relations.rb",
     "generators/talia_base/templates/ontologies/hyper_ontology.owl",
     "generators/talia_base/templates/ontologies/hyper_ontology.pprj",
     "generators/talia_base/templates/ontologies/hyper_ontology.repository",
     "generators/talia_base/templates/ontologies/scholar_0.1.owl",
     "generators/talia_base/templates/public/images/talia_core/building.png",
     "generators/talia_base/templates/public/images/talia_core/document-horizontal-text.png",
     "generators/talia_base/templates/public/images/talia_core/document.png",
     "generators/talia_base/templates/public/images/talia_core/gear.png",
     "generators/talia_base/templates/public/images/talia_core/group.png",
     "generators/talia_base/templates/public/images/talia_core/image.png",
     "generators/talia_base/templates/public/images/talia_core/imagebig.png",
     "generators/talia_base/templates/public/images/talia_core/letter.png",
     "generators/talia_base/templates/public/images/talia_core/map.png",
     "generators/talia_base/templates/public/images/talia_core/period.png",
     "generators/talia_base/templates/public/images/talia_core/person.png",
     "generators/talia_base/templates/public/images/talia_core/person_default.png",
     "generators/talia_base/templates/public/images/talia_core/place.png",
     "generators/talia_base/templates/public/images/talia_core/source.png",
     "generators/talia_base/templates/public/images/talia_core/television.png",
     "generators/talia_base/templates/public/images/talia_core/text.png",
     "generators/talia_base/templates/public/images/talia_core/type.png",
     "generators/talia_base/templates/public/images/talia_core/video.png",
     "generators/talia_base/templates/public/stylesheets/talia_core/images/arrow.png",
     "generators/talia_base/templates/public/stylesheets/talia_core/images/contents_top_left.gif",
     "generators/talia_base/templates/public/stylesheets/talia_core/images/header_bg.gif",
     "generators/talia_base/templates/public/stylesheets/talia_core/images/left_edge.gif",
     "generators/talia_base/templates/public/stylesheets/talia_core/images/line.png",
     "generators/talia_base/templates/public/stylesheets/talia_core/images/logo.gif",
     "generators/talia_base/templates/public/stylesheets/talia_core/main.css",
     "generators/talia_base/templates/script/configure_talia",
     "generators/talia_base/templates/script/prepare_images",
     "generators/talia_base/templates/script/setup_talia_backend",
     "generators/talia_base/templates/talia.sh",
     "generators/talia_base/templates/tasks/talia_core.rk",
     "lib/JXslt/jxslt.rb",
     "lib/core_ext.rb",
     "lib/core_ext/platform.rb",
     "lib/core_ext/string.rb",
     "lib/custom_template.rb",
     "lib/loader_helper.rb",
     "lib/mysql.rb",
     "lib/progressbar.rb",
     "lib/talia_core.rb",
     "lib/talia_core/active_source.rb",
     "lib/talia_core/active_source_parts/class_methods.rb",
     "lib/talia_core/active_source_parts/finders.rb",
     "lib/talia_core/active_source_parts/predicate_handler.rb",
     "lib/talia_core/active_source_parts/rdf.rb",
     "lib/talia_core/active_source_parts/sql_helper.rb",
     "lib/talia_core/active_source_parts/xml/base_builder.rb",
     "lib/talia_core/active_source_parts/xml/generic_reader.rb",
     "lib/talia_core/active_source_parts/xml/rdf_builder.rb",
     "lib/talia_core/active_source_parts/xml/source_builder.rb",
     "lib/talia_core/active_source_parts/xml/source_reader.rb",
     "lib/talia_core/agent.rb",
     "lib/talia_core/background_jobs/job.rb",
     "lib/talia_core/background_jobs/progress_job.rb",
     "lib/talia_core/data_types/data_loader.rb",
     "lib/talia_core/data_types/data_record.rb",
     "lib/talia_core/data_types/delayed_copier.rb",
     "lib/talia_core/data_types/file_record.rb",
     "lib/talia_core/data_types/file_store.rb",
     "lib/talia_core/data_types/iip_data.rb",
     "lib/talia_core/data_types/iip_loader.rb",
     "lib/talia_core/data_types/image_data.rb",
     "lib/talia_core/data_types/media_link.rb",
     "lib/talia_core/data_types/mime_mapping.rb",
     "lib/talia_core/data_types/path_helpers.rb",
     "lib/talia_core/data_types/pdf_data.rb",
     "lib/talia_core/data_types/simple_text.rb",
     "lib/talia_core/data_types/temp_file_handling.rb",
     "lib/talia_core/data_types/xml_data.rb",
     "lib/talia_core/dummy_handler.rb",
     "lib/talia_core/errors.rb",
     "lib/talia_core/initializer.rb",
     "lib/talia_core/ordered_source.rb",
     "lib/talia_core/property_string.rb",
     "lib/talia_core/rdf_import.rb",
     "lib/talia_core/rdf_resource.rb",
     "lib/talia_core/semantic_collection_item.rb",
     "lib/talia_core/semantic_collection_wrapper.rb",
     "lib/talia_core/semantic_property.rb",
     "lib/talia_core/semantic_relation.rb",
     "lib/talia_core/source.rb",
     "lib/talia_core/source_transfer_object.rb",
     "lib/talia_core/source_types/collection.rb",
     "lib/talia_core/source_types/dc_resource.rb",
     "lib/talia_core/source_types/dummy_source.rb",
     "lib/talia_core/workflow.rb",
     "lib/talia_core/workflow/base.rb",
     "lib/talia_core/workflow/publication_workflow.rb",
     "lib/talia_dependencies.rb",
     "lib/talia_util.rb",
     "lib/talia_util/bar_progressor.rb",
     "lib/talia_util/configuration/config_file.rb",
     "lib/talia_util/configuration/database_config.rb",
     "lib/talia_util/configuration/mysql_database_setup.rb",
     "lib/talia_util/image_conversions.rb",
     "lib/talia_util/import_job_helper.rb",
     "lib/talia_util/io_helper.rb",
     "lib/talia_util/progressable.rb",
     "lib/talia_util/progressbar.rb",
     "lib/talia_util/rake_tasks.rb",
     "lib/talia_util/rdf_update.rb",
     "lib/talia_util/some_sigla.xml",
     "lib/talia_util/test_helpers.rb",
     "lib/talia_util/util.rb",
     "lib/version.rb",
     "tasks/talia_core_tasks.rake"
  ]
  s.homepage = %q{http://trac.talia.discovery-project.eu/}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.required_ruby_version = Gem::Requirement.new(">= 1.8.6")
  s.requirements = ["rdflib (Redland RDF) + Ruby bindings (for Redland store)"]
  s.rubygems_version = %q{1.3.5}
  s.summary = %q{The core elements of the Talia Digital Library system}
  s.test_files = [
    "test/custom_template_test.rb",
     "test/test_helper.rb",
     "test/core_ext/string_test.rb",
     "test/talia_core/active_source_predicate_test.rb",
     "test/talia_core/active_source_rdf_test.rb",
     "test/talia_core/active_source_test.rb",
     "test/talia_core/generic_xml_test.rb",
     "test/talia_core/initializer_test.rb",
     "test/talia_core/ordered_source_test.rb",
     "test/talia_core/property_string_test.rb",
     "test/talia_core/rdf_resource_test.rb",
     "test/talia_core/semantic_collection_item_test.rb",
     "test/talia_core/source_reader_test.rb",
     "test/talia_core/source_test.rb",
     "test/talia_core/source_transfer_object_test.rb",
     "test/talia_core/workflow_test.rb",
     "test/talia_core/data_types/data_loader_test.rb",
     "test/talia_core/data_types/data_record_test.rb",
     "test/talia_core/data_types/file_record_test.rb",
     "test/talia_core/data_types/iip_data_test.rb",
     "test/talia_core/data_types/image_data_test.rb",
     "test/talia_core/data_types/mime_mapping_test.rb",
     "test/talia_core/data_types/pdf_data_test.rb",
     "test/talia_core/data_types/xml_data_test.rb",
     "test/talia_core/workflow/publication_workflow_test.rb",
     "test/talia_core/workflow/user_class_for_workflow.rb",
     "test/talia_core/workflow/workflow_base_test.rb",
     "test/talia_util/import_job_helper_test.rb",
     "test/talia_util/io_helper_test.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<activerecord>, [">= 2.0.5"])
      s.add_runtime_dependency(%q<activesupport>, [">= 2.0.5"])
      s.add_runtime_dependency(%q<activerdf_net7>, [">= 1.6.13"])
      s.add_runtime_dependency(%q<assit>, [">= 0.1.2"])
      s.add_runtime_dependency(%q<semantic_naming>, [">= 2.0.6"])
      s.add_runtime_dependency(%q<bjj>, [">= 1.0.2"])
      s.add_runtime_dependency(%q<hpricot>, [">= 0.6.1"])
      s.add_runtime_dependency(%q<oai>, [">= 0.0.12"])
      s.add_runtime_dependency(%q<builder>, [">= 2.1.2"])
      s.add_runtime_dependency(%q<optiflag>, [">= 0.6.5"])
      s.add_runtime_dependency(%q<rake>, [">= 0.7.1"])
    else
      s.add_dependency(%q<activerecord>, [">= 2.0.5"])
      s.add_dependency(%q<activesupport>, [">= 2.0.5"])
      s.add_dependency(%q<activerdf_net7>, [">= 1.6.13"])
      s.add_dependency(%q<assit>, [">= 0.1.2"])
      s.add_dependency(%q<semantic_naming>, [">= 2.0.6"])
      s.add_dependency(%q<bjj>, [">= 1.0.2"])
      s.add_dependency(%q<hpricot>, [">= 0.6.1"])
      s.add_dependency(%q<oai>, [">= 0.0.12"])
      s.add_dependency(%q<builder>, [">= 2.1.2"])
      s.add_dependency(%q<optiflag>, [">= 0.6.5"])
      s.add_dependency(%q<rake>, [">= 0.7.1"])
    end
  else
    s.add_dependency(%q<activerecord>, [">= 2.0.5"])
    s.add_dependency(%q<activesupport>, [">= 2.0.5"])
    s.add_dependency(%q<activerdf_net7>, [">= 1.6.13"])
    s.add_dependency(%q<assit>, [">= 0.1.2"])
    s.add_dependency(%q<semantic_naming>, [">= 2.0.6"])
    s.add_dependency(%q<bjj>, [">= 1.0.2"])
    s.add_dependency(%q<hpricot>, [">= 0.6.1"])
    s.add_dependency(%q<oai>, [">= 0.0.12"])
    s.add_dependency(%q<builder>, [">= 2.1.2"])
    s.add_dependency(%q<optiflag>, [">= 0.6.5"])
    s.add_dependency(%q<rake>, [">= 0.7.1"])
  end
end

