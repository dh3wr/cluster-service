defmodule Cluster.Router do
  use Plug.Router

  plug Cluster.Plug.Api

  plug :match
  plug :dispatch

  post "/cluster/discovery" do
    {:ok, data, conn} = conn |> read_body

    params = data |> Poison.decode!
    node = params |> Map.get("name")
    auth_key = params |> Map.get("auth_key")

    if Cluster.CouchDB.auth(node, auth_key) do
      nodes = Cluster.Discovery.nodes() |> Poison.encode!
      send_resp(conn, 200, nodes)
    else
      send_resp(conn, 403, "Forbidden")
    end
  end

  get "/cluster/nodes" do
    nodes = Cluster.Discovery.nodes()
    |> Stream.map(fn {id, node} ->
      {id, Map.delete(node, "couchdb")}
    end)
    |> Map.new
    |> Poison.encode!

    send_resp(conn, 200, nodes)
  end

  get "/cluster/reachable_nodes" do
    nodes = Cluster.Discovery.reachable_nodes()
    |> Stream.map(fn {id, node} ->
      {id, Map.delete(node, "couchdb")}
    end)
    |> Map.new
    |> Poison.encode!

    send_resp(conn, 200, nodes)
  end

  match _ do
    send_resp(conn, 404, "Not found")
  end
end
