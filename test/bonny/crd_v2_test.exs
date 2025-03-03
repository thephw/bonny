defmodule Bonny.CRDV2Test do
  @moduledoc false

  use ExUnit.Case, async: true

  alias Bonny.CRD.Version
  alias Bonny.CRDV2, as: MUT

  doctest MUT

  describe "new!/1" do
    test "wraps versions if only one given" do
      crd =
        MUT.new!(
          names: %{singular: "somekind", plural: "somekinds", kind: "SomeKind", shortNames: []},
          group: "example.xom",
          version: struct!(Version, name: "v1")
        )

      assert is_list(crd.versions)
      assert 1 == length(crd.versions)
    end
  end

  describe "to_manifest" do
    test "creates manifest" do
      crd =
        MUT.new!(
          names: %{singular: "somekind", plural: "somekinds", kind: "SomeKind", shortNames: []},
          group: "example.xom",
          versions: [struct!(Version, name: "v1")],
          scope: :Namespaced
        )

      expected = %{
        apiVersion: "apiextensions.k8s.io/v1",
        kind: "CustomResourceDefinition",
        metadata: %{labels: %{"k8s-app" => "bonny"}, name: "somekinds.example.xom"},
        spec: %{
          group: "example.xom",
          names: %{kind: "SomeKind", plural: "somekinds", shortNames: [], singular: "somekind"},
          scope: :Namespaced,
          versions: [
            %Bonny.CRD.Version{
              name: "v1",
              served: true,
              storage: true,
              deprecated: false,
              deprecationWarning: nil,
              schema: %{
                openAPIV3Schema: %{type: :object, "x-kubernetes-preserve-unknown-fields": true}
              },
              additionalPrinterColumns: []
            }
          ]
        }
      }

      actual = MUT.to_manifest(crd)
      assert expected == actual
    end

    test "raises if no version with storage flag set to true" do
      crd =
        MUT.new!(
          names: %{singular: "somekind", plural: "somekinds", kind: "SomeKind", shortNames: []},
          group: "example.xom",
          scope: :Namespaced
        )
        |> MUT.update_versions(&struct!(&1, storage: false))

      assert_raise(
        ArgumentError,
        ~r/Only one single version of a CRD can have the attribute "storage" set to true./,
        fn ->
          MUT.to_manifest(crd)
        end
      )
    end
  end
end
